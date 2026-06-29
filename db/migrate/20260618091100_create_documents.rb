class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :document_category, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.bigint :uploaded_by_id, null: false
      t.datetime :published_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :documents, :uploaded_by_id
    add_index :documents, :visibility
    add_index :documents, :status
    add_index :documents, :published_at
    add_index :documents, :expires_at
    add_index :documents, [ :document_category_id, :status ]
    add_index :documents, [ :visibility, :status, :published_at ]
    add_foreign_key :documents, :users, column: :uploaded_by_id
  end
end
