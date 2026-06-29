class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  scope :latest, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { action.present? ? where(action: action) : all }
  scope :by_user, ->(user_id) { user_id.present? ? where(user_id: user_id) : all }
  scope :from_date, ->(date) {
    parsed_date = parse_filter_date(date)
    parsed_date.present? ? where(created_at: parsed_date.beginning_of_day..) : all
  }
  scope :to_date, ->(date) {
    parsed_date = parse_filter_date(date)
    parsed_date.present? ? where(created_at: ..parsed_date.end_of_day) : all
  }
  scope :by_auditable, ->(record) {
    record.present? ? where(auditable: record) : all
  }

  def self.action_options
    distinct.order(:action).pluck(:action)
  end

  def self.parse_filter_date(date)
    return if date.blank?

    Time.zone.parse(date.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def action_label
    action.to_s.tr("._", " ").titleize
  end

  def record_label
    return "System" if auditable_type.blank?

    [ auditable_type, auditable_id ].compact.join(" #")
  end
end
