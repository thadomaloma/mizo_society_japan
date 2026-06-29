class EventPublisher
  def self.call(event, actor:)
    new(event, actor: actor).call
  end

  def initialize(event, actor:)
    @event = event
    @actor = actor
  end

  def call
    unless event.publishable?
      event.errors.add(:base, "Cancelled or completed events cannot be published")
      raise ActiveRecord::RecordInvalid, event
    end

    Event.transaction do
      event.update!(
        status: :published,
        published_at: event.published_at || Time.current
      )
      NotificationCreator.event_created(event, actor: actor)
      AuditLogger.call(
        user: actor,
        action: "event_published",
        auditable: event,
        metadata: { title: event.title, start_time: event.start_time }
      )
    end

    event
  end

  private

  attr_reader :event, :actor
end
