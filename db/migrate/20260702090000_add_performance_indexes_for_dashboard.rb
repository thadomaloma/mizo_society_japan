class AddPerformanceIndexesForDashboard < ActiveRecord::Migration[8.1]
  def change
    add_index :notifications, [ :recipient_id, :created_at ],
      name: "index_notifications_on_recipient_id_and_created_at",
      if_not_exists: true

    add_index :membership_payments, [ :user_id, :created_at ],
      name: "index_membership_payments_on_user_id_and_created_at",
      if_not_exists: true

    add_index :welfare_cases, [ :user_id, :status, :submitted_at ],
      name: "index_welfare_cases_on_user_status_submitted_at",
      if_not_exists: true
  end
end
