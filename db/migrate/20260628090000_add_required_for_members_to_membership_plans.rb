class AddRequiredForMembersToMembershipPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :membership_plans, :required_for_members, :boolean, null: false, default: false
    add_index :membership_plans, [ :active, :required_for_members ], name: "index_membership_plans_on_active_and_required"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE membership_plans
          SET required_for_members = TRUE
          FROM membership_plan_types
          WHERE membership_plans.membership_plan_type_id = membership_plan_types.id
            AND membership_plan_types.code = 'membership'
        SQL
      end
    end
  end
end
