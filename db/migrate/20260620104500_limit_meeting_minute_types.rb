class LimitMeetingMinuteTypes < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET meeting_type = 2
      WHERE meeting_type NOT IN (1, 2)
    SQL

    change_column_default :meeting_minutes, :meeting_type, from: 0, to: 1
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Legacy meeting types were converted to Office Bearers Meeting and cannot be restored automatically."
  end
end
