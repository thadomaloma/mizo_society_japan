class ReplaceMeetingTypeWithMeetingTime < ActiveRecord::Migration[8.1]
  def up
    add_column :meeting_minutes, :meeting_time, :time
    remove_index :meeting_minutes, :meeting_type if index_exists?(:meeting_minutes, :meeting_type)
    remove_column :meeting_minutes, :meeting_type
  end

  def down
    add_column :meeting_minutes, :meeting_type, :integer, null: false, default: 0
    add_index :meeting_minutes, :meeting_type
    remove_column :meeting_minutes, :meeting_time
  end
end
