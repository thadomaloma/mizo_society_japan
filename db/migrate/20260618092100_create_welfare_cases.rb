class CreateWelfareCases < ActiveRecord::Migration[8.1]
  def change
    create_table :welfare_cases do |t|
      t.references :welfare_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.bigint :assigned_to_id
      t.string :title, null: false
      t.text :description, null: false
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.boolean :confidential, null: false, default: true
      t.datetime :submitted_at, null: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :welfare_cases, :assigned_to_id
    add_index :welfare_cases, :priority
    add_index :welfare_cases, :status
    add_index :welfare_cases, :submitted_at
    add_index :welfare_cases, :resolved_at
    add_index :welfare_cases, [ :status, :priority, :submitted_at ]
    add_foreign_key :welfare_cases, :users, column: :assigned_to_id
  end
end
