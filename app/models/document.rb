class Document < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    image/png
    image/jpeg
  ].freeze

  belongs_to :document_category
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :visibility, {
    public_access: 0,
    members_only: 1,
    office_bearers_only: 2,
    finance_only: 3,
    executive_committee_only: 4
  }, default: :members_only
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  validates :title, :visibility, :status, presence: true
  validate :file_content_type

  scope :latest, -> { order(published_at: :desc, created_at: :desc) }
  scope :active, -> { published.where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_category, ->(category_id) { category_id.present? ? where(document_category_id: category_id) : all }
  scope :by_visibility, ->(visibility) { visibilities.key?(visibility.to_s) ? where(visibility: visibility) : all }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    where("title ILIKE :query OR description ILIKE :query", query: pattern)
  }
  scope :visible_to, lambda { |user|
    base_scope = active
    next base_scope.public_access if user.blank?
    next base_scope if user.event_manager?

    visible_visibilities = %i[public_access members_only]
    visible_visibilities << :office_bearers_only if user.office_bearer?
    visible_visibilities << :executive_committee_only if user.minutes_access?
    visible_visibilities << :finance_only if user.finance_team?

    base_scope.where(visibility: visible_visibilities)
  }

  def self.official_letter_visibility_options
    %w[office_bearers_only executive_committee_only]
  end

  def official_letter?
    document_category&.name == "Official Letters" || letter_data.present?
  end

  def letter_attribute(key)
    letter_data.fetch(key.to_s, nil).presence || OfficialLetterDocxBuilder.default_for(key)
  end

  def file_size
    file.attached? ? file.blob.byte_size : 0
  end

  def file_icon
    case file_extension
    when "pdf" then "file-text"
    when "docx" then "file-type"
    when "xlsx" then "file-spreadsheet"
    when "png", "jpg", "jpeg" then "image"
    else "file"
    end
  end

  def file_extension
    return "" unless file.attached?

    file.filename.extension_without_delimiter.to_s.downcase
  end

  def downloadable_by?(user)
    return false unless published? && !expired?
    return true if public_access?
    return false if user.blank?
    return true if members_only?
    return true if office_bearers_only? && user.office_bearer?
    return true if executive_committee_only? && user.minutes_access?
    return true if finance_only? && user.finance_team?

    false
  end

  def publishable?
    !archived?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def file_content_type
    return unless file.attached?
    return if file.blob.content_type.in?(ALLOWED_CONTENT_TYPES)

    errors.add(:file, "must be a PDF, DOCX, XLSX, PNG, or JPG file")
  end
end
