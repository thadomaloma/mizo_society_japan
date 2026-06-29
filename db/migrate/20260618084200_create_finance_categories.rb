class CreateFinanceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :finance_categories do |t|
      t.string :name, null: false
      t.integer :category_type, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :finance_categories, [ :category_type, :active ]
    add_index :finance_categories, [ :name, :category_type ], unique: true
  end
end
