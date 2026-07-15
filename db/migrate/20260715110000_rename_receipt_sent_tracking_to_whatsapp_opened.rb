class RenameReceiptSentTrackingToWhatsappOpened < ActiveRecord::Migration[8.1]
  def change
    rename_column :membership_payments, :receipt_sent_at, :receipt_whatsapp_opened_at
    rename_column :membership_payments, :receipt_sent_by_id, :receipt_whatsapp_opened_by_id
  end
end
