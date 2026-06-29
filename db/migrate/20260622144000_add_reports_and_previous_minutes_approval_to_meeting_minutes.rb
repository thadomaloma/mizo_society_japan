class AddReportsAndPreviousMinutesApprovalToMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minutes, :previous_minutes_approval, :text
    add_column :meeting_minutes, :reports, :text
  end
end
