class AddAdjournmentToMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minutes, :adjournment, :text
  end
end
