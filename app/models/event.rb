class Event < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :event_category
  has_many :event_registrations, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :volunteer_slots, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_one_attached :cover_image
  has_many_attached :photos
  attr_accessor :start_time_of_day

  enum :status, { draft: 0, published: 1, cancelled: 2, completed: 3 }, default: :draft
  enum :visibility, { public_event: 0, members_only: 1, office_bearers_only: 2 }, default: :members_only

  validates :title, :event_date, :venue, :description, :start_time, :end_time, :event_category, :status, :visibility, presence: true
  validates :max_participants, allow_blank: true, numericality: { only_integer: true, greater_than: 0 }
  validate :end_time_after_start_time

  before_validation :sync_schedule_fields
  before_validation :sync_legacy_event_fields
  before_validation :assign_default_category

  scope :latest, -> { order(start_time: :desc, created_at: :desc) }
  scope :upcoming, -> { where(start_time: Time.current..).order(start_time: :asc) }
  scope :past, -> { where(end_time: ...Time.current).order(start_time: :desc) }
  scope :by_category, ->(category_id) { category_id.present? ? where(event_category_id: category_id) : all }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :visible_to_members, -> { published.where(visibility: [ :public_event, :members_only ]) }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    where("title ILIKE :query OR location ILIKE :query OR city ILIKE :query", query: pattern)
  }

  def upcoming?
    start_time.present? && start_time >= Time.current
  end

  def past?
    end_time.present? && end_time < Time.current
  end

  def registration_open?
    registration_required? && published? && upcoming? && deadline_open? && (max_participants.blank? || available_spots.positive?)
  end

  def registration_status
    return "Not required" unless registration_required?
    return "Open" if registration_open?
    return "Full" if max_participants.present? && available_spots.zero?

    "Closed"
  end

  def publishable?
    draft? || published?
  end

  def full_location
    [ venue.presence || location, city, prefecture ].compact_blank.join(", ")
  end

  def registered_by?(user)
    return false if user.blank?

    event_registrations.where(user: user).where.not(status: :cancelled).exists?
  end

  def attendee_count
    attendances.count
  end

  def rsvp_count
    event_registrations.going.count
  end

  def available_spots
    return if max_participants.blank?

    [ max_participants - rsvp_count, 0 ].max
  end

  def start_time_of_day
    @start_time_of_day.presence || start_time&.strftime("%H:%M")
  end

  private

  def sync_schedule_fields
    return if event_date.blank? || start_time_of_day.blank?

    parsed_time = Time.zone.parse("#{event_date} #{start_time_of_day}")
    self.start_time = parsed_time
    self.end_time = parsed_time + 2.hours if end_time.blank? || end_time < parsed_time
  end

  def sync_legacy_event_fields
    self.location = venue if venue.present?
    self.capacity = max_participants if max_participants.present?
  end

  def assign_default_category
    self.event_category ||= EventCategory.active.ordered.first
  end

  def deadline_open?
    registration_deadline.blank? || registration_deadline >= Time.current
  end

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end
