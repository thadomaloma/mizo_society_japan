class RemoveStripeFromMembershipPayments < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE membership_payments SET payment_method = 4 WHERE payment_method = 2"
    execute "UPDATE membership_payments SET status = 0 WHERE status IN (1, 2)"

    remove_index :membership_payments, :stripe_checkout_session_id if index_exists?(:membership_payments, :stripe_checkout_session_id)
    remove_index :membership_payments, :stripe_payment_intent_id if index_exists?(:membership_payments, :stripe_payment_intent_id)
    remove_index :membership_payments, :stripe_customer_id if index_exists?(:membership_payments, :stripe_customer_id)
    remove_index :membership_payments, :stripe_status if index_exists?(:membership_payments, :stripe_status)

    remove_column :membership_payments, :stripe_checkout_session_id if column_exists?(:membership_payments, :stripe_checkout_session_id)
    remove_column :membership_payments, :stripe_payment_intent_id if column_exists?(:membership_payments, :stripe_payment_intent_id)
    remove_column :membership_payments, :stripe_customer_id if column_exists?(:membership_payments, :stripe_customer_id)
    remove_column :membership_payments, :stripe_payment_method_type if column_exists?(:membership_payments, :stripe_payment_method_type)
    remove_column :membership_payments, :stripe_status if column_exists?(:membership_payments, :stripe_status)
    remove_column :membership_payments, :expires_at if column_exists?(:membership_payments, :expires_at)
  end

  def down
    add_column :membership_payments, :stripe_checkout_session_id, :string unless column_exists?(:membership_payments, :stripe_checkout_session_id)
    add_column :membership_payments, :stripe_payment_intent_id, :string unless column_exists?(:membership_payments, :stripe_payment_intent_id)
    add_column :membership_payments, :stripe_customer_id, :string unless column_exists?(:membership_payments, :stripe_customer_id)
    add_column :membership_payments, :stripe_payment_method_type, :string unless column_exists?(:membership_payments, :stripe_payment_method_type)
    add_column :membership_payments, :stripe_status, :string unless column_exists?(:membership_payments, :stripe_status)
    add_column :membership_payments, :expires_at, :datetime unless column_exists?(:membership_payments, :expires_at)

    add_index :membership_payments, :stripe_checkout_session_id, unique: true unless index_exists?(:membership_payments, :stripe_checkout_session_id)
    add_index :membership_payments, :stripe_payment_intent_id unless index_exists?(:membership_payments, :stripe_payment_intent_id)
    add_index :membership_payments, :stripe_customer_id unless index_exists?(:membership_payments, :stripe_customer_id)
    add_index :membership_payments, :stripe_status unless index_exists?(:membership_payments, :stripe_status)
  end
end
