class MeetingMinutePublisher
  def self.call(meeting_minute, actor:)
    new(meeting_minute, actor: actor).call
  end

  def initialize(meeting_minute, actor:)
    @meeting_minute = meeting_minute
    @actor = actor
  end

  def call
    meeting_minute.with_lock do
      return meeting_minute if meeting_minute.published?

      unless meeting_minute.publishable?
        meeting_minute.errors.add(:base, "Only draft meeting minutes can be published")
        raise ActiveRecord::RecordInvalid, meeting_minute
      end

      meeting_minute.update!(
        status: :published,
        published_at: meeting_minute.published_at || Time.current
      )
      NotificationCreator.meeting_minute_published(meeting_minute, actor: actor)
      AuditLogger.call(
        user: actor,
        action: "meeting_minute_published",
        auditable: meeting_minute,
        metadata: { title: meeting_minute.title, meeting_date: meeting_minute.meeting_date }
      )
      meeting_minute
    end
  end

  private

  attr_reader :meeting_minute, :actor
end
