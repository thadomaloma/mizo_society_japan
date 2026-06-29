class EventCalendarExporter
  def self.call(event)
    new(event).call
  end

  def initialize(event)
    @event = event
  end

  def call
    [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Mizo Society of Japan//MSJ Portal//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "UID:msj-event-#{event.id}@mizosociety.jp",
      "DTSTAMP:#{timestamp(Time.current)}",
      "DTSTART:#{timestamp(event.start_time)}",
      "DTEND:#{timestamp(event.end_time)}",
      "SUMMARY:#{escape(event.title)}",
      "LOCATION:#{escape(event.full_location)}",
      "DESCRIPTION:#{escape(event.description)}",
      "END:VEVENT",
      "END:VCALENDAR"
    ].join("\r\n") + "\r\n"
  end

  private

  attr_reader :event

  def timestamp(value)
    value.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def escape(value)
    value.to_s.gsub("\\", "\\\\").gsub(";", "\\;").gsub(",", "\\,").gsub(/\r?\n/, "\\n")
  end
end
