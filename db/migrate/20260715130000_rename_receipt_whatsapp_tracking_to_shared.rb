class RenameReceiptWhatsappTrackingToShared < ActiveRecord::Migration[8.1]
  def change
    rename_column :membership_payments, :receipt_whatsapp_opened_at, :receipt_shared_at
    rename_column :membership_payments, :receipt_whatsapp_opened_by_id, :receipt_shared_by_id
  end
end
