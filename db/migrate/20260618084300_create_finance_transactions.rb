class CreateFinanceTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :finance_transactions do |t|
      t.references :finance_category, null: false, foreign_key: true
      t.bigint :recorded_by_id, null: false
      t.bigint :approved_by_id
      t.integer :transaction_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :transaction_date, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.string :reference_number

      t.timestamps
    end

    add_index :finance_transactions, :recorded_by_id
    add_index :finance_transactions, :approved_by_id
    add_index :finance_transactions, :transaction_date
    add_index :finance_transactions, [ :transaction_type, :status, :transaction_date ], name: "idx_finance_transactions_on_type_status_date"
    add_index :finance_transactions, :reference_number
    add_foreign_key :finance_transactions, :users, column: :recorded_by_id
    add_foreign_key :finance_transactions, :users, column: :approved_by_id
  end
end
