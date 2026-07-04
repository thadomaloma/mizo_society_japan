class RemapOnlineCardPaymentsToBankTransfer < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE membership_payments SET payment_method = 1 WHERE payment_method = 5"
  end

  def down
    # Intentionally irreversible: online card checkout has been removed, and
    # historical records should remain valid bank-transfer/manual records.
  end
end
