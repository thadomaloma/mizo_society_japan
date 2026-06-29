class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.bigint :checked_in_by_id
      t.datetime :checked_in_at, null: false
      t.text :note

      t.timestamps
    end

    add_index :attendances, :checked_in_by_id
    add_index :attendances, [ :event_id, :user_id ], unique: true
    add_index :attendances, :checked_in_at
    add_foreign_key :attendances, :users, column: :checked_in_by_id
  end
end
