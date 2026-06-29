class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :location
      t.string :city
      t.string :prefecture
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :event_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :visibility, null: false, default: 1
      t.integer :capacity
      t.datetime :registration_deadline
      t.bigint :created_by_id, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :events, :created_by_id
    add_index :events, :event_type
    add_index :events, :status
    add_index :events, :visibility
    add_index :events, :start_time
    add_index :events, [ :status, :start_time ]
    add_index :events, [ :visibility, :status, :start_time ]
    add_foreign_key :events, :users, column: :created_by_id
  end
end
