class RemoveArchivedStatusFromMeetingMinutes < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET status = 1
      WHERE status = 2
    SQL
  end

  def down
    # Meeting minutes now use only draft and published.
  end
end
