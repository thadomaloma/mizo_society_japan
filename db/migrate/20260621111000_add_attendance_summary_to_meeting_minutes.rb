class AddAttendanceSummaryToMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minutes, :present_count, :integer, null: false, default: 0
    add_column :meeting_minutes, :absent_count, :integer, null: false, default: 0
    add_column :meeting_minutes, :apologies_count, :integer, null: false, default: 0
    add_column :meeting_minutes, :guests_count, :integer, null: false, default: 0
    add_column :meeting_minutes, :attendance_notes, :text
  end
end
