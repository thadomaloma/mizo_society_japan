class AddWritingFieldsToMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minutes, :meeting_time, :time
    add_column :meeting_minutes, :location, :string
    add_column :meeting_minutes, :attendees, :text
    add_column :meeting_minutes, :agenda, :text
    add_column :meeting_minutes, :minutes_body, :text
  end
end
