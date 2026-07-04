class MeetingMinute < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
  ].freeze
  RICH_TEXT_TAGS = %w[p br div strong b em i u ul ol li].freeze
  ATTENDANCE_COUNT_FIELDS = %i[present_count absent_count].freeze

  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file
  has_one_attached :chairman_signature
  has_one_attached :secretary_signature
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :meeting_minute_attendances, dependent: :destroy
  has_many :attending_users, through: :meeting_minute_attendances, source: :user

  enum :status, {
    draft: 0,
    published: 1
  }, default: :draft

  validates :title, :meeting_date, :status, presence: true
  validates :meeting_time, presence: true, on: :create
  validates(*ATTENDANCE_COUNT_FIELDS, numericality: { only_integer: true, greater_than_or_equal_to: 0 })
  validate :summary_contains_text
  validate :file_content_type
  validate :signature_content_type

  before_validation :sanitize_rich_text

  scope :latest, -> { order(meeting_date: :desc, created_at: :desc) }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :by_year, lambda { |year|
    normalized_year = year.to_i
    next all unless normalized_year.positive?

    where(meeting_date: Date.new(normalized_year).all_year)
  }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    where("title ILIKE :query OR summary ILIKE :query", query: pattern)
  }
  scope :visible_to, lambda { |user|
    next all if user&.minute_manager?
    next none if user.blank?
    next published if user.minutes_access?

    none
  }

  def publishable?
    draft?
  end

  def file_size
    file.attached? ? file.blob.byte_size : 0
  end

  def file_icon
    file_extension == "pdf" ? "file-text" : "file-type"
  end

  def file_extension
    return "" unless file.attached?

    file.filename.extension_without_delimiter.to_s.downcase
  end

  def downloadable_by?(user)
    user.present? && (user.minute_manager? || (published? && user.minutes_access?))
  end

  def attendee_ids
    attendance_ids_for(:present)
  end

  def meeting_time_label
    meeting_time&.strftime("%I:%M %p") || "Time not recorded"
  end

  def chairman_signature_display_name
    chairman_signature_name.presence || chairman.presence || "Chairman"
  end

  def chairman_signature_display_title
    chairman_signature_title.presence || "President"
  end

  def secretary_signature_display_name
    secretary_signature_name.presence || minute_recorder.presence || "Secretary"
  end

  def secretary_signature_display_title
    secretary_signature_title.presence || "Gen. Secretary"
  end

  def attendance_total
    ATTENDANCE_COUNT_FIELDS.sum { |field| public_send(field).to_i }
  end

  def attendee_ids=(ids)
    self.attending_user_ids = ids
  end

  def attendance_ids_for(status)
    meeting_minute_attendances.select { |attendance| attendance.status == status.to_s }.map(&:user_id)
  end

  def sync_checkbox_attendance!(attendance_user_ids:, present_ids:)
    allowed_user_ids = User.where(role: User::OFFICE_BEARER_ROLES + User::EXECUTIVE_ROLES).pluck(:id)
    eligible_user_ids = Array(attendance_user_ids).map(&:to_i).uniq & allowed_user_ids
    present_user_ids = Array(present_ids).map(&:to_i).uniq & eligible_user_ids
    absent_user_ids = eligible_user_ids - present_user_ids

    transaction do
      existing_attendances = meeting_minute_attendances.where(user_id: eligible_user_ids).index_by(&:user_id)

      present_user_ids.each do |user_id|
        (existing_attendances[user_id] || meeting_minute_attendances.build(user_id: user_id)).update!(status: :present)
      end

      absent_user_ids.each do |user_id|
        (existing_attendances[user_id] || meeting_minute_attendances.build(user_id: user_id)).update!(status: :absent)
      end

      update!(present_count: present_user_ids.size, absent_count: absent_user_ids.size)
    end
  end

  private

  def file_content_type
    return unless file.attached?
    return if file.blob.content_type.in?(ALLOWED_CONTENT_TYPES)

    errors.add(:file, "must be a PDF file")
  end

  def signature_content_type
    {
      chairman_signature: chairman_signature,
      secretary_signature: secretary_signature
    }.each do |attribute, attachment|
      next unless attachment.attached?
      next if attachment.blob.content_type == "image/png"

      errors.add(attribute, "must be a PNG image")
    end
  end

  def sanitize_rich_text
    self.summary = sanitize_rich_text_value(summary)
    self.decisions = sanitize_rich_text_value(decisions)
    self.adjournment = sanitize_rich_text_value(adjournment)
  end

  def sanitize_rich_text_value(value)
    normalized_value = value.to_s.gsub(/&nbsp;|\u00A0/, " ")
    ActionController::Base.helpers.sanitize(normalized_value, tags: RICH_TEXT_TAGS, attributes: [])
  end

  def summary_contains_text
    return if ActionView::Base.full_sanitizer.sanitize(summary.to_s).strip.present?

    errors.add(:summary, "must include meeting agenda text")
  end
end
