class RemoveMeetingVisibilityAndAddMeetingOfficers < ActiveRecord::Migration[8.1]
  def up
    add_column :meeting_minutes, :chairman, :string
    add_column :meeting_minutes, :minute_recorder, :string
    add_column :meeting_minutes, :opening_prayer, :string
    add_column :meeting_minutes, :call_to_order, :string

    remove_index :meeting_minutes, name: "idx_on_visibility_status_meeting_date_59d3bb2526"
    remove_index :meeting_minutes, :visibility
    remove_column :meeting_minutes, :visibility
  end

  def down
    add_column :meeting_minutes, :visibility, :integer, null: false, default: 0
    add_index :meeting_minutes, :visibility
    add_index :meeting_minutes, [ :visibility, :status, :meeting_date ], name: "idx_on_visibility_status_meeting_date_59d3bb2526"

    remove_column :meeting_minutes, :call_to_order
    remove_column :meeting_minutes, :opening_prayer
    remove_column :meeting_minutes, :minute_recorder
    remove_column :meeting_minutes, :chairman
  end
end
