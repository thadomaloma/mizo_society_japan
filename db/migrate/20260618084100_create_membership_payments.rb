class CreateMembershipPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :membership_payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :membership_plan, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :payment_year, null: false
      t.integer :payment_month
      t.integer :payment_method, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.date :paid_on
      t.bigint :approved_by_id
      t.string :reference_number
      t.text :notes

      t.timestamps
    end

    add_index :membership_payments, :approved_by_id
    add_index :membership_payments, :payment_year
    add_index :membership_payments, [ :status, :created_at ]
    add_index :membership_payments, [ :user_id, :payment_year, :payment_month ], name: "idx_membership_payments_on_user_and_period"
    add_index :membership_payments, :reference_number
    add_foreign_key :membership_payments, :users, column: :approved_by_id
  end
end
