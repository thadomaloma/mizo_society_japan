class RemoveOnlineCheckoutFromMembershipPayments < ActiveRecord::Migration[8.1]
  def change
    remove_index :membership_payments, :stripe_checkout_session_id, if_exists: true
    remove_index :membership_payments, :stripe_payment_intent_id, if_exists: true
    remove_index :membership_payments, :stripe_customer_id, if_exists: true
    remove_index :membership_payments, :stripe_status, if_exists: true

    remove_column :membership_payments, :stripe_checkout_session_id, :string, if_exists: true
    remove_column :membership_payments, :stripe_payment_intent_id, :string, if_exists: true
    remove_column :membership_payments, :stripe_customer_id, :string, if_exists: true
    remove_column :membership_payments, :stripe_payment_method_type, :string, if_exists: true
    remove_column :membership_payments, :stripe_status, :string, if_exists: true
    remove_column :membership_payments, :checkout_expires_at, :datetime, if_exists: true
  end
end
