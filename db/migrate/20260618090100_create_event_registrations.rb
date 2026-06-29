class CreateEventRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :event_registrations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.text :note
      t.datetime :registered_at, null: false

      t.timestamps
    end

    add_index :event_registrations, [ :event_id, :user_id ], unique: true
    add_index :event_registrations, [ :event_id, :status ]
    add_index :event_registrations, :registered_at
  end
end
