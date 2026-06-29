class CreateWelfareCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :welfare_categories do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :welfare_categories, :active
    add_index :welfare_categories, :name, unique: true
  end
end
