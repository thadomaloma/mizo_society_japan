class CreateDocumentCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :document_categories do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :document_categories, :active
    add_index :document_categories, :name, unique: true
    add_index :document_categories, [ :active, :position ]
  end
end
