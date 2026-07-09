class PreventDuplicateActiveMembershipPayments < ActiveRecord::Migration[8.1]
  BLOCKING_STATUSES = [ 0, 3, 4, 5, 8 ].freeze

  def up
    cancel_duplicate_active_payments

    add_index :membership_payments,
      "user_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)",
      unique: true,
      where: "status IN (#{BLOCKING_STATUSES.join(',')})",
      name: "idx_unique_active_membership_payment_period"
  end

  def down
    remove_index :membership_payments, name: "idx_unique_active_membership_payment_period", if_exists: true
  end

  private

  def cancel_duplicate_active_payments
    duplicate_ids = duplicate_period_payment_ids + duplicate_one_time_payment_ids
    duplicate_ids.uniq!

    return if duplicate_ids.blank?

    say_with_time "Cancelling duplicate active membership payment records" do
      execute(<<~SQL.squish)
        UPDATE membership_payments
        SET status = 6,
            notes = CONCAT_WS(E'\n', NULLIF(notes, ''), 'Automatically cancelled during duplicate payment cleanup.'),
            updated_at = CURRENT_TIMESTAMP
        WHERE id IN (#{duplicate_ids.join(',')})
      SQL
    end
  end

  def duplicate_period_payment_ids
    select_values(<<~SQL.squish)
      WITH ranked_payments AS (
        SELECT id,
          ROW_NUMBER() OVER (
            PARTITION BY user_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)
            ORDER BY
              CASE status
                WHEN 3 THEN 0
                WHEN 8 THEN 1
                WHEN 0 THEN 2
                WHEN 4 THEN 3
                WHEN 5 THEN 4
                ELSE 5
              END,
              updated_at DESC,
              id ASC
          ) AS duplicate_rank
        FROM membership_payments
        WHERE status IN (#{BLOCKING_STATUSES.join(',')})
      )
      SELECT id FROM ranked_payments WHERE duplicate_rank > 1
    SQL
  end

  def duplicate_one_time_payment_ids
    select_values(<<~SQL.squish)
      WITH ranked_payments AS (
        SELECT membership_payments.id,
          ROW_NUMBER() OVER (
            PARTITION BY membership_payments.user_id, membership_payments.membership_plan_id
            ORDER BY
              CASE membership_payments.status
                WHEN 3 THEN 0
                WHEN 8 THEN 1
                WHEN 0 THEN 2
                WHEN 4 THEN 3
                WHEN 5 THEN 4
                ELSE 5
              END,
              membership_payments.updated_at DESC,
              membership_payments.id ASC
          ) AS duplicate_rank
        FROM membership_payments
        INNER JOIN membership_plans ON membership_plans.id = membership_payments.membership_plan_id
        WHERE membership_payments.status IN (#{BLOCKING_STATUSES.join(',')})
          AND membership_plans.billing_cycle = 2
      )
      SELECT id FROM ranked_payments WHERE duplicate_rank > 1
    SQL
  end
end
