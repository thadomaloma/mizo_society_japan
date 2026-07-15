class WelfareCase < ApplicationRecord
  OPEN_STATUSES = %w[submitted reviewing in_progress].freeze
  CLOSED_STATUSES = %w[resolved rejected].freeze

  belongs_to :user
  belongs_to :welfare_category
  belongs_to :assigned_to, class_name: "User", optional: true

  has_many :welfare_notes, dependent: :destroy
  has_many :welfare_attachments, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, default: :medium
  enum :status, {
    submitted: 0,
    reviewing: 1,
    in_progress: 2,
    resolved: 3,
    rejected: 4
  }, default: :submitted

  before_validation :assign_submitted_at, if: -> { submitted_at.blank? }

  validates :title, :description, :priority, :status, presence: true
  validate :assigned_officer_is_eligible

  scope :latest, -> { order(submitted_at: :desc, created_at: :desc) }
  scope :open_cases, -> { where(status: OPEN_STATUSES) }
  scope :urgent, -> { where(priority: :urgent) }
  scope :assigned, -> { where.not(assigned_to_id: nil) }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :resolved_this_month, -> { resolved.where(resolved_at: Date.current.all_month) }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :by_priority, ->(priority) { priorities.key?(priority.to_s) ? where(priority: priority) : all }
  scope :by_category, ->(category_id) { category_id.present? ? where(welfare_category_id: category_id) : all }
  scope :by_assigned_to, ->(user_id) { user_id.present? ? where(assigned_to_id: user_id) : all }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    left_joins(user: :member_profile)
      .where(
        "welfare_cases.title ILIKE :query OR welfare_cases.description ILIKE :query OR users.email ILIKE :query OR users.name ILIKE :query OR member_profiles.full_name ILIKE :query OR member_profiles.membership_number ILIKE :query",
        query: pattern
      )
  }

  def open?
    status.in?(OPEN_STATUSES)
  end

  def closed?
    status.in?(CLOSED_STATUSES)
  end

  def assigned?
    assigned_to_id.present?
  end

  def resolvable?
    open?
  end

  def editable_by_member?
    submitted?
  end

  def status_badge_class
    {
      "submitted" => "bg-amber-50 text-amber-700 ring-amber-200",
      "reviewing" => "bg-sky-50 text-sky-700 ring-sky-200",
      "in_progress" => "bg-indigo-50 text-indigo-700 ring-indigo-200",
      "resolved" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "rejected" => "bg-red-50 text-red-700 ring-red-200"
    }.fetch(status, "bg-gray-100 text-gray-700 ring-gray-200")
  end

  private

  def assign_submitted_at
    self.submitted_at = Time.current
  end

  def assigned_officer_is_eligible
    return if assigned_to.blank?
    return if assigned_to.active? && assigned_to.role.in?(User::WELFARE_CASE_ASSIGNEE_ROLES)

    errors.add(:assigned_to, "must be an active President, Secretary, or Assistant Secretary")
  end
end
