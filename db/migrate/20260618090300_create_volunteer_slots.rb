class CreateVolunteerSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :volunteer_slots do |t|
      t.references :event, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :needed_count, null: false
      t.integer :assigned_count, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :volunteer_slots, [ :event_id, :status ]
  end
end
