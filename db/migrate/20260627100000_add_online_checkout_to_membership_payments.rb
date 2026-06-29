class AddOnlineCheckoutToMembershipPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :membership_payments, :stripe_checkout_session_id, :string
    add_column :membership_payments, :stripe_payment_intent_id, :string
    add_column :membership_payments, :stripe_customer_id, :string
    add_column :membership_payments, :stripe_payment_method_type, :string
    add_column :membership_payments, :stripe_status, :string
    add_column :membership_payments, :checkout_expires_at, :datetime

    add_index :membership_payments, :stripe_checkout_session_id, unique: true
    add_index :membership_payments, :stripe_payment_intent_id
    add_index :membership_payments, :stripe_customer_id
    add_index :membership_payments, :stripe_status
  end
end
