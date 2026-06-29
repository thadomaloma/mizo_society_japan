class CreateResolutions < ActiveRecord::Migration[8.1]
  def change
    create_table :resolutions do |t|
      t.references :meeting_minute, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.date :due_date
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :resolutions, [ :status, :due_date ]
  end
end
