class AddStripeFieldsToMembershipPayments < ActiveRecord::Migration[8.1]
  def up
    add_column :membership_payments, :stripe_checkout_session_id, :string
    add_column :membership_payments, :stripe_payment_intent_id, :string
    add_column :membership_payments, :stripe_customer_id, :string
    add_column :membership_payments, :stripe_payment_method_type, :string
    add_column :membership_payments, :stripe_status, :string
    add_column :membership_payments, :expires_at, :datetime

    change_column :membership_payments, :paid_on, :datetime

    execute <<~SQL.squish
      UPDATE membership_payments
      SET status = CASE status
        WHEN 1 THEN 3
        WHEN 2 THEN 3
        WHEN 3 THEN 4
        ELSE 0
      END
    SQL

    add_index :membership_payments, :stripe_checkout_session_id, unique: true
    add_index :membership_payments, :stripe_payment_intent_id
    add_index :membership_payments, :stripe_customer_id
    add_index :membership_payments, :stripe_status
  end

  def down
    remove_index :membership_payments, :stripe_status
    remove_index :membership_payments, :stripe_customer_id
    remove_index :membership_payments, :stripe_payment_intent_id
    remove_index :membership_payments, :stripe_checkout_session_id

    execute <<~SQL.squish
      UPDATE membership_payments
      SET status = CASE status
        WHEN 3 THEN 1
        WHEN 4 THEN 3
        ELSE 0
      END
    SQL

    change_column :membership_payments, :paid_on, :date

    remove_column :membership_payments, :expires_at
    remove_column :membership_payments, :stripe_status
    remove_column :membership_payments, :stripe_payment_method_type
    remove_column :membership_payments, :stripe_customer_id
    remove_column :membership_payments, :stripe_payment_intent_id
    remove_column :membership_payments, :stripe_checkout_session_id
  end
end
