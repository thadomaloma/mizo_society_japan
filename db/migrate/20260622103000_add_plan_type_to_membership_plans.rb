class AddPlanTypeToMembershipPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :membership_plans, :plan_type, :integer, null: false, default: 0
    add_index :membership_plans, [ :plan_type, :active ]
  end
end
