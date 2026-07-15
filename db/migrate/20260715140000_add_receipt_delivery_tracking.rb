class AddReceiptDeliveryTracking < ActiveRecord::Migration[8.1]
  def change
    rename_column :membership_payments, :receipt_shared_at, :receipt_whatsapp_opened_at
    rename_column :membership_payments, :receipt_shared_by_id, :receipt_whatsapp_opened_by_id
    add_column :membership_payments, :receipt_sent_at, :datetime
    add_reference :membership_payments,
      :receipt_sent_by,
      foreign_key: { to_table: :users, name: "fk_membership_payments_receipt_sent_by" }
  end
end
