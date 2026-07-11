class AddReceiptTrackingToMembershipPayments < ActiveRecord::Migration[8.1]
  def change
    add_reference :membership_payments, :receipt_sent_by, foreign_key: { to_table: :users }, index: true
    add_column :membership_payments, :receipt_sent_at, :datetime
  end
end
