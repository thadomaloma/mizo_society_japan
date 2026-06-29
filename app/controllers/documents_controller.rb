class DocumentsController < ApplicationController
  skip_forgery_protection only: :official_letter_template

  before_action :set_document, only: [ :show, :edit, :update, :destroy, :download, :download_letter, :publish, :archive ]
  before_action :set_category_options, only: [ :new, :create, :edit, :update ]

  def index
    authorize Document
    @can_manage_documents = policy(Document).update?
    @query = params[:query]
    @category_id = params[:category_id].presence
    @visibility = params[:visibility].presence
    @status = @can_manage_documents ? params[:status].presence : nil
    @category_options = DocumentCategory.active.ordered

    @documents = policy_scope(Document)
      .includes(:document_category, :uploaded_by, file_attachment: :blob)
      .search(@query)
      .by_category(@category_id)
      .by_visibility(@visibility)
      .by_status(@status)
      .latest
  end

  def official_letter_template
    authorize Document, :create?
    letter_attributes = official_letter_params.to_h
    filename = "#{letter_attributes[:subject].presence || "msj-official-letter"}".parameterize
    filename = "msj-official-letter" if filename.blank?

    send_data OfficialLetterDocxBuilder.call(letter_attributes),
      filename: "#{filename}.docx",
      type: OfficialLetterDocxBuilder::CONTENT_TYPE,
      disposition: "attachment"
  end

  def show
    authorize @document
  end

  def new
    @document = Document.new(document_category: official_letter_category, visibility: :office_bearers_only)
    authorize @document
  end

  def create
    @document = Document.new(document_attributes)
    @document.uploaded_by = current_user
    authorize @document

    if @document.save
      audit_document("document_created")
      redirect_to @document, notice: "Letter was saved as a draft."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @document
  end

  def update
    authorize @document

    if @document.update(document_attributes)
      audit_document("document_updated")
      redirect_to @document, notice: "Letter was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @document
    metadata = document_metadata
    @document.destroy
    AuditLogger.call(user: current_user, action: "document_deleted", metadata: metadata, request: request)
    redirect_to documents_path, notice: "Letter was deleted."
  end

  def download
    authorize @document, :download?
    unless @document.file.attached?
      redirect_to @document, alert: "Attach the final letter file before downloading."
      return
    end

    send_data @document.file.download,
      filename: @document.file.filename.to_s,
      type: @document.file.content_type,
      disposition: "attachment"
  end

  def download_letter
    authorize @document, :show?
    filename = @document.title.to_s.parameterize.presence || "msj-official-letter"

    send_data OfficialLetterDocxBuilder.call(@document.letter_data),
      filename: "#{filename}.docx",
      type: OfficialLetterDocxBuilder::CONTENT_TYPE,
      disposition: "attachment"
  end

  def publish
    authorize @document, :publish?
    DocumentPublisher.call(@document, actor: current_user)
    redirect_to @document, notice: "Letter was published."
  rescue ActiveRecord::RecordInvalid
    redirect_to @document, alert: @document.errors.full_messages.to_sentence
  end

  def archive
    authorize @document, :archive?
    @document.update!(status: :archived)
    audit_document("document_archived")
    redirect_to @document, notice: "Letter was archived."
  end

  private

  def set_document
    @document = policy_scope(Document).includes(:document_category, :uploaded_by, file_attachment: :blob).find(params[:id])
  end

  def set_category_options
    categories = DocumentCategory.active
    if @document&.document_category_id.present?
      categories = categories.or(DocumentCategory.where(id: @document.document_category_id))
    end

    @category_options = categories.ordered
  end

  def document_params
    params.require(:document).permit(:title, :description, :document_category_id, :visibility, :expires_at, :file)
  end

  def document_attributes
    attributes = document_params.to_h
    if attributes["title"].blank? && params[:official_letter].present?
      attributes["title"] = generated_letter_title
    end
    if params[:official_letter].present?
      attributes["document_category_id"] = official_letter_category.id
      attributes["letter_data"] = official_letter_attributes
    elsif attributes["document_category_id"].blank?
      attributes["document_category_id"] = official_letter_category.id
    end
    attributes
  end

  def official_letter_attributes
    official_letter_params.to_h.transform_values { |value| value.to_s.strip }
  end

  def official_letter_category
    DocumentCategory.find_or_create_by!(name: "Official Letters") do |category|
      category.description = "Formal outgoing letters and archived final copies."
      category.active = true
      category.position = 0
    end.tap do |category|
      category.update!(active: true) unless category.active?
    end
  end

  def generated_letter_title
    letter_attributes = official_letter_params
    letter_attributes[:subject].presence ||
      letter_attributes[:reference_number].presence ||
      "Untitled Official Letter"
  end

  def official_letter_params
    params.fetch(:official_letter, {}).permit(
      :reference_number,
      :dated_place,
      :letter_date,
      :president_name,
      :president_phone,
      :secretary_name,
      :secretary_phone,
      :motto,
      :recipient_block,
      :salutation,
      :subject,
      :body,
      :closing,
      :signer_name,
      :signer_title,
      :organization_name,
      :organization_location
    )
  end

  def audit_document(action)
    AuditLogger.call(user: current_user, action: action, auditable: @document, metadata: document_metadata, request: request)
  end

  def document_metadata
    { title: @document.title, category: @document.document_category.name, visibility: @document.visibility, status: @document.status }
  end
end
