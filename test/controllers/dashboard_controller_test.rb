require "test_helper"
require "zlib"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    ensure_profile_for(@member)
  end

  test "member dashboard shows focused member information and hides restricted navigation" do
    sign_in @member

    get root_path

    assert_response :success
    assert_select "a[aria-label='Go to dashboard'][href='#{root_path}']"
    assert_includes response.body, "Payments Due"
    assert_includes response.body, "Community Overview"
    assert_includes response.body, "Active Members"
    assert_includes response.body, "Few members"
    assert_includes response.body, "Updates"
    assert_includes response.body, "Upcoming Events"
    assert_includes response.body, "Profile"
    assert_not_includes response.body, "Latest Documents"
    assert_not_includes response.body, "My Welfare Requests"
    assert_not_includes response.body, 'href="/meeting_minutes"'
    assert_not_includes response.body, 'href="/documents"'
    assert_includes response.body, 'href="/welfare_cases"'
  end

  test "member dashboard keeps documents low priority even when a visible document exists" do
    create_visible_document!
    sign_in @member

    get root_path

    assert_response :success
    assert_not_includes response.body, "Latest Documents"
    assert_not_includes response.body, 'href="/documents"'
  end

  test "member dashboard shows upcoming events only when visible events exist" do
    create_visible_event!(title: "MSJ Picnic")
    sign_in @member

    get root_path

    assert_response :success
    assert_includes response.body, "Upcoming Events"
    assert_includes response.body, "MSJ Picnic"
    assert_includes response.body, 'href="/events"'
    assert_match(/Updates.*Upcoming Events.*Profile/m, response.body)
  end

  test "member dashboard announcement stat counts all visible announcements" do
    4.times { |index| create_announcement!(title: "Published Announcement #{index + 1}") }
    create_announcement!(title: "Draft Announcement", status: :draft)
    create_announcement!(title: "Expired Announcement", expires_at: 1.day.ago)
    sign_in @member

    get root_path

    assert_response :success
    assert_match(/Announcements.*4/m, response.body)
    assert_not_includes response.body, "Draft Announcement"
    assert_not_includes response.body, "Expired Announcement"
  end

  test "executive member uses member style dashboard with payments reports and announcements" do
    announcement = create_announcement!(title: "Executive Update")
    executive_member = create_profiled_member!("executive-dashboard@example.com", role: :executive_member)

    sign_in executive_member

    get root_path

    assert_response :success
    assert_includes response.body, "Welcome back, #{executive_member.display_name}"
    assert_includes response.body, "Your payments, updates, and profile activity are shown here."
    assert_includes response.body, "Announcements &amp; Updates"
    assert_includes response.body, announcement.title
    assert_includes response.body, 'href="/payments"'
    assert_includes response.body, 'href="/admin/reports"'
    assert_not_includes response.body, "Open admin"

    mobile_nav = Nokogiri::HTML(response.body).at_css('nav[aria-label="Mobile navigation"]')
    mobile_labels = mobile_nav.css("a span:last-child").map { |span| span.text.strip }
    assert_includes mobile_labels, "Ask AI"
    assert_not_includes mobile_labels, "Welfare"
  end

  test "regular member style dashboard and sidebar do not show reports" do
    member = create_profiled_member!("regular-dashboard@example.com", role: :member)
    sign_in member

    get root_path

    assert_response :success
    assert_includes response.body, 'href="/payments"'
    assert_not_includes response.body, 'href="/admin/reports"'
    assert_not_includes response.body, 'href="/meeting_minutes"'
    assert_not_includes response.body, "Open admin"
  end

  test "member dashboard shows kanji prefecture names in romaji" do
    @member.member_profile.update!(prefecture: "東京都")
    create_profiled_member!("tokyo-one@example.com", prefecture: "東京都")
    create_profiled_member!("tokyo-two@example.com", prefecture: "東京都")
    sign_in @member

    get root_path

    assert_response :success
    assert_includes response.body, "Community Overview"
    assert_match(/Tokyo.*3/m, response.body)
    assert_not_includes response.body, "東京都"
  end

  private

  def create_visible_document!
    document = Document.new(
      title: "Member Guide",
      description: "Guide",
      document_category: document_categories(:forms),
      visibility: :members_only,
      status: :published,
      published_at: Time.current,
      uploaded_by: users(:admin)
    )
    document.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.pdf")),
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    document.save!
  end

  def create_visible_event!(title:)
    Event.create!(
      title: title,
      event_category: event_categories(:general),
      created_by: users(:admin),
      event_date: Date.tomorrow,
      start_time_of_day: "11:00",
      venue: "Shinjuku, Tokyo",
      description: "A published MSJ community event.",
      status: :published,
      visibility: :members_only,
      published_at: Time.current
    )
  end

  def create_announcement!(title:, status: :published, expires_at: nil)
    Announcement.create!(
      title: title,
      body: "Important information for Mizo Society of Japan members.",
      category: :general,
      status: status,
      published_at: status == :published ? Time.current : nil,
      expires_at: expires_at,
      author: users(:admin)
    )
  end

  def create_profiled_member!(email, prefecture: "Tokyo", role: :member)
    user = User.create!(
      email: email,
      name: email.split("@").first.titleize,
      password: "password123",
      role: role
    )
    ensure_profile_for(user, mobile_number: unique_mobile_for(user), prefecture: prefecture)
    user
  end

  def ensure_profile_for(user, mobile_number: "09024681357", prefecture: "Tokyo")
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: mobile_number,
        date_of_birth: Date.new(1990, 1, 1),
        family_status: :single,
      postal_code: "169-0075",
      prefecture: prefecture,
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end

  def unique_mobile_for(user)
    suffix = (Zlib.crc32(user.email) % 100_000_000).to_s.rjust(8, "0")
    "090#{suffix}"
  end
end
