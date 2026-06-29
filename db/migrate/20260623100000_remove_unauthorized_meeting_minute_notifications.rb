class RemoveUnauthorizedMeetingMinuteNotifications < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      DELETE FROM notifications
      USING users
      WHERE notifications.recipient_id = users.id
        AND notifications.notifiable_type = 'MeetingMinute'
        AND users.role NOT IN (0, 1, 2, 3, 4, 5, 6, 8, 9)
    SQL
  end

  def down
  end
end
