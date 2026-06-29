class SimplifyMeetingMinutes < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET status = CASE status
        WHEN 0 THEN 0
        WHEN 1 THEN 0
        WHEN 2 THEN 1
        WHEN 3 THEN 1
        WHEN 4 THEN 2
        ELSE 0
      END
    SQL

    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET visibility = CASE visibility
        WHEN 1 THEN 2
        WHEN 4 THEN 1
        ELSE 2
      END
    SQL

    execute <<~SQL.squish
      UPDATE meeting_minutes
      SET summary = COALESCE(NULLIF(summary, ''), NULLIF(minutes_body, ''), 'No summary recorded.')
      WHERE summary IS NULL OR summary = ''
    SQL

    rename_column :meeting_minutes, :location, :venue
    add_column :meeting_minutes, :decisions, :text
    remove_column :meeting_minutes, :meeting_time
    remove_column :meeting_minutes, :agenda
    remove_column :meeting_minutes, :minutes_body
    remove_reference :meeting_minutes, :approved_by, foreign_key: { to_table: :users }
    drop_table :resolutions

    change_column_default :meeting_minutes, :meeting_type, from: 1, to: 0
    change_column_default :meeting_minutes, :visibility, from: 1, to: 0
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Minutes were simplified and resolution tracking was removed."
  end
end
