class CreateWelfareNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :welfare_notes do |t|
      t.references :welfare_case, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :internal, null: false, default: true

      t.timestamps
    end

    add_index :welfare_notes, :internal
    add_index :welfare_notes, [ :welfare_case_id, :created_at ]
  end
end
