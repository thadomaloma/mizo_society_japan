class CreateMembershipPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :membership_plans do |t|
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :billing_cycle, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.text :description

      t.timestamps
    end

    add_index :membership_plans, :name, unique: true
    add_index :membership_plans, [ :active, :billing_cycle ]
  end
end
