module Reports
  class EventsReport
    def summary
      {
        total_events: Event.count,
        upcoming_events: Event.published.upcoming.count,
        completed_events: Event.completed.count,
        rsvp_count: EventRegistration.going.count,
        attendance_count: Attendance.count,
        upcoming_list: Event.published.upcoming.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        headers: [ "Title", "Type", "Status", "Visibility", "Start Time", "End Time", "RSVP Count", "Attendance Count" ],
        rows: Event.latest.map do |event|
          [
            event.title,
            event.event_category.name,
            event.status,
            event.visibility,
            event.start_time,
            event.end_time,
            event.rsvp_count,
            event.attendee_count
          ]
        end
      )
    end
  end
end
