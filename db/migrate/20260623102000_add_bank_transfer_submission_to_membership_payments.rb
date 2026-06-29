class AddBankTransferSubmissionToMembershipPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :membership_payments, :transferred_on, :date
    add_column :membership_payments, :transfer_amount, :decimal, precision: 10, scale: 2
    add_column :membership_payments, :transfer_reference_name, :string

    add_index :membership_payments, :transferred_on
    add_index :membership_payments, :transfer_reference_name
  end
end
