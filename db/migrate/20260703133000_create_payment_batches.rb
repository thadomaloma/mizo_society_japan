class CreatePaymentBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_batches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :approved_by, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :transfer_amount, precision: 10, scale: 2
      t.date :transferred_on
      t.string :transfer_reference_name
      t.datetime :approved_at
      t.text :notes

      t.timestamps
    end

    add_reference :membership_payments, :payment_batch, foreign_key: true
    add_index :payment_batches, [ :status, :created_at ]
    add_index :payment_batches, :transfer_reference_name
  end
end
