class CreateVolunteerSignups < ActiveRecord::Migration[8.1]
  def change
    create_table :volunteer_signups do |t|
      t.references :volunteer_slot, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :note
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :volunteer_signups, [ :volunteer_slot_id, :user_id ], unique: true
    add_index :volunteer_signups, [ :volunteer_slot_id, :status ]
  end
end
