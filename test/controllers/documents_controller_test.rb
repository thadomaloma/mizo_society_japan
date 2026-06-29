require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    @category = document_categories(:forms)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "president can upload and publish a document" do
    sign_in @president

    assert_difference -> { Document.count }, 1 do
      post documents_path, params: { document: document_params(title: "MSJ Membership Form") }
    end

    document = Document.last
    assert_redirected_to document_path(document)
    assert document.draft?
    assert document.file.attached?

    patch publish_document_path(document)

    assert_redirected_to document_path(document)
    assert document.reload.published?
  end

  test "president can download an MSJ official letter docx" do
    sign_in @president

    post official_letter_template_documents_path, params: {
      official_letter: {
        reference_number: "MSJ/LET/2026/001",
        dated_place: "Tokyo",
        letter_date: "29 June, 2026",
        recipient_block: "The President,\nCentral Mizo Society,\nUSA.",
        subject: "Lawmthu sawina",
        body: "Mizo Society of Japan hmingin chibai kan buk a che.",
        signer_name: "Lalramliana",
        signer_title: "President"
      }
    }

    assert_response :success
    assert_equal OfficialLetterDocxBuilder::CONTENT_TYPE, response.media_type
    assert_includes response.headers["Content-Disposition"], "lawmthu-sawina.docx"
    assert_docx_uses_a4_page_size(response.body)
    assert_docx_subject_is_left_aligned(response.body, "Lawmthu sawina")
    assert_docx_has_header_rule(response.body)
  end

  test "president can save a draft letter without final file" do
    sign_in @president

    assert_difference -> { Document.count }, 1 do
      post documents_path, params: {
        document: document_params(title: "Draft Letter Without File").except(:file)
      }
    end

    document = Document.last
    assert_redirected_to document_path(document)
    assert document.draft?
    assert_not document.file.attached?

    patch publish_document_path(document)

    assert_redirected_to document_path(document)
    assert document.reload.draft?
    assert_equal "File must be attached before publishing", flash[:alert]
  end

  test "president can save a draft letter without typing archive title" do
    sign_in @president

    assert_difference -> { Document.count }, 1 do
      post documents_path, params: {
        document: document_params(title: "").except(:file),
        official_letter: {
          reference_number: "MSJ/LET/2026/009",
          subject: "Lawmthu sawina"
        }
      }
    end

    document = Document.last
    assert_redirected_to document_path(document)
    assert_equal "Lawmthu sawina", document.title
    assert_equal "Official Letters", document.document_category.name
    assert_equal "MSJ/LET/2026/009", document.letter_data["reference_number"]
    assert_equal "Lawmthu sawina", document.letter_data["subject"]
    assert document.draft?

    get document_path(document)
    assert_response :success
    assert_includes response.body, "MSJ/LET/2026/009"
    assert_includes response.body, "Lawmthu sawina"

    get download_letter_document_path(document)
    assert_response :success
    assert_equal OfficialLetterDocxBuilder::CONTENT_TYPE, response.media_type
    assert_docx_uses_a4_page_size(response.body)
  end

  test "president can save a draft letter without choosing category" do
    sign_in @president

    assert_difference -> { Document.count }, 1 do
      post documents_path, params: {
        document: document_params(title: "No Category Letter").except(:document_category_id, :file),
        official_letter: {
          subject: "No category draft"
        }
      }
    end

    document = Document.last
    assert_redirected_to document_path(document)
    assert_equal "Official Letters", document.document_category.name
    assert document.draft?
  end

  test "members can see and download published documents but not drafts" do
    published = create_document(title: "Published MSJ Form", status: :published)
    draft = create_document(title: "Draft MSJ Form", status: :draft)
    sign_in @member

    get documents_path
    assert_response :success
    assert_includes response.body, published.title
    assert_not_includes response.body, draft.title

    get document_path(published)
    assert_response :success

    get download_document_path(published)
    assert_response :success
    assert_equal "application/pdf", response.media_type

    get document_path(draft)
    assert_response :not_found
  end

  test "documents index does not show meeting minutes card" do
    sign_in @president

    get documents_path

    assert_response :success
    assert_not_includes response.body, "Open meeting records and decisions."
  end

  test "letters use clean public path and old documents path redirects" do
    sign_in @president

    assert_equal "/letters", documents_path
    assert_equal "/letters/new", new_document_path

    get "/documents"
    assert_redirected_to "/letters"
  end

  test "documents filters by search category visibility and status" do
    target = create_document(title: "Lawmthu Sawina Letter", status: :published, visibility: :office_bearers_only)
    create_document(title: "Finance Committee Letter", status: :published, visibility: :finance_only)
    create_document(title: "Draft Lawmthu Letter", status: :draft, visibility: :office_bearers_only)
    sign_in @president

    get documents_path, params: {
      query: "Lawmthu",
      category_id: @category.id,
      visibility: "office_bearers_only",
      status: "published"
    }

    assert_response :success
    assert_includes response.body, target.title
    assert_not_includes response.body, "Finance Committee Letter"
    assert_not_includes response.body, "Draft Lawmthu Letter"
  end

  test "members cannot access finance-only documents" do
    document = create_document(title: "Finance Committee Report", status: :published, visibility: :finance_only)
    sign_in @member

    get document_path(document)
    assert_response :not_found

    sign_in @member
    get download_document_path(document)
    assert_response :not_found
  end

  test "members cannot access office bearer or executive committee letters" do
    office_letter = create_document(title: "Office Bearer Letter", status: :published, visibility: :office_bearers_only)
    executive_letter = create_document(title: "Executive Committee Letter", status: :published, visibility: :executive_committee_only)
    sign_in @member

    get documents_path
    assert_response :success
    assert_not_includes response.body, office_letter.title
    assert_not_includes response.body, executive_letter.title

    get document_path(office_letter)
    assert_response :not_found

    get document_path(executive_letter)
    assert_response :not_found
  end

  test "executive members can access executive committee letters but not office bearer letters" do
    executive = create_user("Executive Member", "document_executive@example.test", :executive_member, "07012345678")
    office_letter = create_document(title: "Office Bearer Letter", status: :published, visibility: :office_bearers_only)
    executive_letter = create_document(title: "Executive Committee Letter", status: :published, visibility: :executive_committee_only)
    sign_in executive

    get documents_path
    assert_response :success
    assert_includes response.body, executive_letter.title
    assert_not_includes response.body, office_letter.title
  end

  private

  def document_params(title:)
    {
      title: title,
      description: "An official document for Mizo Society of Japan members.",
      document_category_id: @category.id,
      visibility: :members_only,
      file: fixture_file_upload("sample.pdf", "application/pdf")
    }
  end

  def create_document(title:, status:, visibility: :members_only, category: @category)
    document = Document.new(document_params(title: title).merge(visibility: visibility, document_category_id: category.id))
    document.uploaded_by = @president
    document.status = status
    document.published_at = Time.current if status == :published
    document.save!
    document
  end

  def ensure_profile_for(user, mobile_number: "09012345678")
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: mobile_number,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end

  def create_user(name, email, role, mobile_number)
    User.create!(
      name: name,
      email: email,
      password: "password123",
      role: role,
      active: true
    ).tap { |user| ensure_profile_for(user, mobile_number: mobile_number) }
  end

  def assert_docx_uses_a4_page_size(body)
    document_xml = nil
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      document_xml = zip.read("word/document.xml")
    end

    assert_includes document_xml, '<w:pgSz w:w="11906" w:h="16838"/>'
    assert_includes document_xml, '<w:pgMar w:top="907" w:right="1021" w:bottom="907" w:left="1021"'
  end

  def assert_docx_subject_is_left_aligned(body, subject)
    document_xml = nil
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      document_xml = zip.read("word/document.xml")
    end

    subject_index = document_xml.index("<w:t xml:space=\"preserve\">#{ERB::Util.html_escape(subject)}</w:t>")
    assert subject_index, "Expected DOCX subject text to be present"
    paragraph_start = document_xml.rindex("<w:p>", subject_index)
    paragraph_end = document_xml.index("</w:p>", subject_index)
    subject_paragraph = document_xml[paragraph_start..paragraph_end]

    assert_not_includes subject_paragraph, 'w:jc w:val="right"'
  end

  def assert_docx_has_header_rule(body)
    document_xml = nil
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      document_xml = zip.read("word/document.xml")
    end

    assert_equal 1, document_xml.scan('<w:bottom w:val="single" w:sz="8"').size
    assert_includes document_xml, '<w:pBdr><w:bottom w:val="single" w:sz="8" w:space="1" w:color="000000"/></w:pBdr>'
  end
end
