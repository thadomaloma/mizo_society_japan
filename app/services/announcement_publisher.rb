class AnnouncementPublisher
  def self.call(announcement, actor:)
    new(announcement, actor: actor).call
  end

  def initialize(announcement, actor:)
    @announcement = announcement
    @actor = actor
  end

  def call
    unless announcement.publishable?
      announcement.errors.add(:base, "Archived announcements cannot be published")
      raise ActiveRecord::RecordInvalid, announcement
    end

    Announcement.transaction do
      announcement.update!(
        status: :published,
        published_at: announcement.published_at || Time.current
      )
      NotificationCreator.announcement_published(announcement, actor: actor)
      AuditLogger.call(
        user: actor,
        action: "announcement_published",
        auditable: announcement,
        metadata: { title: announcement.title, status: announcement.status }
      )
    end

    announcement
  end

  private

  attr_reader :announcement, :actor
end
