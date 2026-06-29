class RemoveAllMembersVisibilityFromMeetingMinutes < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET visibility = 1
      WHERE visibility = 0
    SQL

    change_column_default :meeting_minutes, :visibility, from: 0, to: 1
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "All Members meeting minutes were safely converted to OB only and cannot be restored automatically."
  end
end
