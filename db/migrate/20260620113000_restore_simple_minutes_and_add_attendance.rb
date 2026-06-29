class RestoreSimpleMinutesAndAddAttendance < ActiveRecord::Migration[8.1]
  class LegacyMeetingMinute < ActiveRecord::Base
    self.table_name = "meeting_minutes"
  end

  class LegacyRichText < ActiveRecord::Base
    self.table_name = "action_text_rich_texts"
  end

  def up
    add_column :meeting_minutes, :minutes_body, :text unless column_exists?(:meeting_minutes, :minutes_body)
    LegacyMeetingMinute.reset_column_information

    restore_rich_text_bodies if table_exists?(:action_text_rich_texts)
    preserve_legacy_attendance_notes if column_exists?(:meeting_minutes, :attendees)

    drop_table :action_text_rich_texts if table_exists?(:action_text_rich_texts)
    remove_column :meeting_minutes, :attendees if column_exists?(:meeting_minutes, :attendees)

    create_table :meeting_minute_attendances do |t|
      t.references :meeting_minute, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :meeting_minute_attendances, [ :meeting_minute_id, :user_id ], unique: true,
      name: "index_meeting_minute_attendances_on_minute_and_user"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Rich text was restored to the simple editor and attendance notes were converted to records."
  end

  private

  def restore_rich_text_bodies
    LegacyRichText.where(record_type: "MeetingMinute", name: "content").find_each do |rich_text|
      LegacyMeetingMinute.where(id: rich_text.record_id).update_all(minutes_body: rich_text.body)
    end
  end

  def preserve_legacy_attendance_notes
    LegacyMeetingMinute.where.not(attendees: [ nil, "" ]).find_each do |minute|
      attendance_html = "<div><strong>Attendance:</strong><br>#{ERB::Util.html_escape(minute.attendees).gsub("\n", "<br>")}</div>"
      minutes_body = [ minute.minutes_body.presence, attendance_html ].compact.join

      minute.update_columns(minutes_body: minutes_body)
    end
  end
end
