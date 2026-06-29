class DocumentPublisher
  def self.call(document, actor:)
    new(document, actor: actor).call
  end

  def initialize(document, actor:)
    @document = document
    @actor = actor
  end

  def call
    unless document.publishable?
      document.errors.add(:base, "Archived documents cannot be published")
      raise ActiveRecord::RecordInvalid, document
    end

    unless document.file.attached?
      document.errors.add(:file, "must be attached before publishing")
      raise ActiveRecord::RecordInvalid, document
    end

    Document.transaction do
      document.update!(
        status: :published,
        published_at: document.published_at || Time.current
      )
      NotificationCreator.document_uploaded(document, actor: actor)
      AuditLogger.call(
        user: actor,
        action: "document_uploaded",
        auditable: document,
        metadata: { title: document.title, visibility: document.visibility, status: document.status }
      )
    end

    document
  end

  private

  attr_reader :document, :actor
end
