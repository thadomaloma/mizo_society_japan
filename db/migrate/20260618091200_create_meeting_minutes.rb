class CreateMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_minutes do |t|
      t.string :title, null: false
      t.integer :meeting_type, null: false, default: 0
      t.date :meeting_date, null: false
      t.text :summary
      t.integer :visibility, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.bigint :uploaded_by_id, null: false
      t.bigint :approved_by_id
      t.datetime :approved_at
      t.datetime :published_at

      t.timestamps
    end

    add_index :meeting_minutes, :uploaded_by_id
    add_index :meeting_minutes, :approved_by_id
    add_index :meeting_minutes, :meeting_type
    add_index :meeting_minutes, :meeting_date
    add_index :meeting_minutes, :visibility
    add_index :meeting_minutes, :status
    add_index :meeting_minutes, :published_at
    add_index :meeting_minutes, [ :status, :meeting_date ]
    add_index :meeting_minutes, [ :visibility, :status, :meeting_date ]
    add_foreign_key :meeting_minutes, :users, column: :uploaded_by_id
    add_foreign_key :meeting_minutes, :users, column: :approved_by_id
  end
end
