class AddPortalFieldsToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :event_date, :date
    add_column :events, :venue, :string
    add_column :events, :registration_required, :boolean, null: false, default: false
    add_column :events, :max_participants, :integer

    execute <<~SQL.squish
      UPDATE events
      SET event_date = DATE(start_time),
          venue = location,
          max_participants = capacity,
          registration_required = TRUE
    SQL

    change_column_null :events, :event_date, false
    add_index :events, :event_date
  end

  def down
    remove_index :events, :event_date
    remove_column :events, :max_participants
    remove_column :events, :registration_required
    remove_column :events, :venue
    remove_column :events, :event_date
  end
end
