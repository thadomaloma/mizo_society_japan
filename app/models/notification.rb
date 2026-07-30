class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :action, {
    announcement_published: 0,
    payment_submitted: 1,
    payment_approved: 2,
    finance_transaction_created: 3,
    welfare_case_updated: 4,
    event_created: 5,
    document_uploaded: 6,
    meeting_minute_published: 7,
    welfare_case_submitted: 8,
    welfare_case_assigned: 9,
    welfare_case_resolved: 10,
    welfare_case_rejected: 11
  }

  validates :recipient, :action, :title, presence: true
  after_commit :expire_recipient_notification_count

  scope :latest, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :for_user, ->(user) { where(recipient: user) }
  scope :relevant_to, lambda { |user|
    owned_notifications = for_user(user)
    other_notifications = owned_notifications.where.not(action: actions[:event_created])
    visible_event_notifications = owned_notifications.where(
      action: actions[:event_created],
      notifiable_type: "Event",
      notifiable_id: Event.visible_to(user).select(:id)
    )

    other_notifications.or(visible_event_notifications)
  }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  private

  def expire_recipient_notification_count
    Rails.cache.delete(recipient.notification_count_cache_key) if recipient_id.present?
  end
end
