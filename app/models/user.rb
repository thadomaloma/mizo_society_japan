class User < ApplicationRecord
  ROLES = {
    president: 0,
    vice_president: 8,
    secretary: 1,
    assistant_secretary: 4,
    treasurer: 2,
    finance_secretary: 3,
    journal_secretary: 5,
    executive_member: 6,
    member: 7
  }.freeze

  SUPER_ADMIN_ROLES = %w[president secretary].freeze
  SECRETARIAT_ROLES = (SUPER_ADMIN_ROLES + %w[assistant_secretary]).freeze
  ADMIN_ROLES = SUPER_ADMIN_ROLES
  FINANCE_ADMIN_ROLES = %w[treasurer finance_secretary].freeze
  FINANCE_ROLES = (SUPER_ADMIN_ROLES + FINANCE_ADMIN_ROLES).freeze
  APPROVER_ROLES = %w[president secretary treasurer finance_secretary].freeze
  OBSERVER_OFFICE_BEARER_ROLES = %w[vice_president journal_secretary].freeze
  EXECUTIVE_ROLES = %w[executive_member].freeze
  ADVISORY_VIEWER_ROLES = (OBSERVER_OFFICE_BEARER_ROLES + EXECUTIVE_ROLES).freeze
  WELFARE_MANAGER_ROLES = SECRETARIAT_ROLES
  WELFARE_VIEWER_ROLES = (WELFARE_MANAGER_ROLES + ADVISORY_VIEWER_ROLES).freeze
  WELFARE_CASE_ASSIGNEE_ROLES = WELFARE_MANAGER_ROLES
  CONTENT_ADMIN_ROLES = SECRETARIAT_ROLES
  EVENT_ROLES = SECRETARIAT_ROLES
  MINUTE_MANAGER_ROLES = SECRETARIAT_ROLES
  OFFICE_BEARER_ROLES = %w[
    president
    vice_president
    secretary
    assistant_secretary
    treasurer
    finance_secretary
    journal_secretary
  ].freeze
  REPORT_ROLES = (SUPER_ADMIN_ROLES + FINANCE_ADMIN_ROLES + ADVISORY_VIEWER_ROLES).freeze
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_one :member_profile, dependent: :destroy
  has_many :membership_payments, dependent: :destroy
  has_many :payment_batches, dependent: :destroy
  has_many :approved_membership_payments, class_name: "MembershipPayment", foreign_key: :approved_by_id, dependent: :nullify, inverse_of: :approved_by
  has_many :shared_membership_payment_receipts, class_name: "MembershipPayment", foreign_key: :receipt_shared_by_id, dependent: :nullify, inverse_of: :receipt_shared_by
  has_many :recorded_finance_transactions, class_name: "FinanceTransaction", foreign_key: :recorded_by_id, dependent: :restrict_with_error, inverse_of: :recorded_by
  has_many :approved_finance_transactions, class_name: "FinanceTransaction", foreign_key: :approved_by_id, dependent: :nullify, inverse_of: :approved_by
  has_many :authored_announcements, class_name: "Announcement", foreign_key: :author_id, dependent: :restrict_with_error, inverse_of: :author
  has_many :announcement_reads, dependent: :destroy
  has_many :read_announcements, through: :announcement_reads, source: :announcement
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify, inverse_of: :actor
  has_many :created_events, class_name: "Event", foreign_key: :created_by_id, dependent: :restrict_with_error, inverse_of: :created_by
  has_many :event_registrations, dependent: :destroy
  has_many :registered_events, through: :event_registrations, source: :event
  has_many :attendances, dependent: :destroy
  has_many :attended_events, through: :attendances, source: :event
  has_many :checked_in_attendances, class_name: "Attendance", foreign_key: :checked_in_by_id, dependent: :nullify, inverse_of: :checked_in_by
  has_many :volunteer_signups, dependent: :destroy
  has_many :uploaded_documents, class_name: "Document", foreign_key: :uploaded_by_id, dependent: :restrict_with_error, inverse_of: :uploaded_by
  has_many :uploaded_meeting_minutes, class_name: "MeetingMinute", foreign_key: :uploaded_by_id, dependent: :restrict_with_error, inverse_of: :uploaded_by
  has_many :meeting_minute_attendances, dependent: :destroy
  has_many :welfare_cases, dependent: :destroy
  has_many :assigned_welfare_cases, class_name: "WelfareCase", foreign_key: :assigned_to_id, dependent: :nullify, inverse_of: :assigned_to
  has_many :welfare_notes, dependent: :destroy
  has_many :welfare_attachments, foreign_key: :uploaded_by_id, dependent: :restrict_with_error, inverse_of: :uploaded_by
  has_many :audit_logs, dependent: :nullify

  enum :role, ROLES, default: :member

  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def self.role_label(role)
    role.to_s.humanize.titleize
  end

  def self.from_google_oauth2(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = auth.info.email.to_s.downcase
    user.name = auth.info.name.presence || auth.info.email.to_s.split("@").first
    user.password = Devise.friendly_token[0, 32] if user.encrypted_password.blank?
    user.role ||= :member
    user.save!
    user
  rescue ActiveRecord::RecordInvalid
    existing_user = find_by(email: auth.info.email.to_s.downcase)
    if existing_user.present?
      existing_user.update!(provider: auth.provider, uid: auth.uid)
      existing_user
    else
      user
    end
  end

  def super_admin?
    role.in?(SUPER_ADMIN_ROLES)
  end

  def admin?
    super_admin?
  end

  def finance_admin?
    role.in?(FINANCE_ADMIN_ROLES)
  end

  def finance_team?
    role.in?(FINANCE_ROLES)
  end

  def finance_observer?
    role.in?(OBSERVER_OFFICE_BEARER_ROLES)
  end

  def finance_viewer?
    finance_team? || finance_observer?
  end

  def finance_approver?
    role.in?(APPROVER_ROLES)
  end

  def welfare_manager?
    role.in?(WELFARE_MANAGER_ROLES)
  end

  def welfare_viewer?
    role.in?(WELFARE_VIEWER_ROLES)
  end

  def content_admin?
    role.in?(CONTENT_ADMIN_ROLES)
  end

  def event_team?
    role.in?(EVENT_ROLES)
  end

  def event_manager?
    role.in?(EVENT_ROLES)
  end

  def minute_manager?
    role.in?(MINUTE_MANAGER_ROLES)
  end

  def executive_committee?
    role.in?(EXECUTIVE_ROLES)
  end

  def observer_office_bearer?
    role.in?(OBSERVER_OFFICE_BEARER_ROLES)
  end

  def advisory_viewer?
    role.in?(ADVISORY_VIEWER_ROLES)
  end

  def minutes_access?
    office_bearer? || advisory_viewer?
  end

  def report_viewer?
    role.in?(REPORT_ROLES)
  end

  def operations_team?
    super_admin? || observer_office_bearer? || finance_admin? || event_manager? || welfare_manager? || minute_manager?
  end

  def office_bearer?
    role.in?(OFFICE_BEARER_ROLES)
  end

  def display_name
    member_profile&.full_name.presence || name.presence || email
  end

  def profile_complete?
    member_profile&.complete? || false
  end

  def unread_notifications_count
    Rails.cache.fetch(notification_count_cache_key, expires_in: 1.minute) do
      notifications.unread.count
    end
  end

  def notification_count_cache_key
    "users/#{id}/notifications/unread_count/v1"
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end
end
