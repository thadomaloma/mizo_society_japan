class LimitMeetingMinuteVisibilities < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET visibility = 1
      WHERE visibility IN (2, 3)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Legacy finance and welfare minute visibility was converted to Office Bearers Only and cannot be restored automatically."
  end
end
