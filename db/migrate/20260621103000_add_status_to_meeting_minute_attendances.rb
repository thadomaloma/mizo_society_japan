class AddStatusToMeetingMinuteAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minute_attendances, :status, :integer, null: false, default: 0
    add_index :meeting_minute_attendances, [ :meeting_minute_id, :status ]
  end
end
