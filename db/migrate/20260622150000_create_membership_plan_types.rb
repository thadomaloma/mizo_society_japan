class CreateMembershipPlanTypes < ActiveRecord::Migration[8.1]
  DEFAULT_TYPES = {
    "membership" => "Membership",
    "donation" => "Donation",
    "fundraiser" => "Fundraiser",
    "other_fee" => "Other Fee"
  }.freeze

  def up
    create_table :membership_plan_types do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :membership_plan_types, :name, unique: true
    add_index :membership_plan_types, :code, unique: true
    add_index :membership_plan_types, :active

    DEFAULT_TYPES.each do |code, name|
      execute <<~SQL.squish
        INSERT INTO membership_plan_types (name, code, active, created_at, updated_at)
        VALUES (#{connection.quote(name)}, #{connection.quote(code)}, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    add_reference :membership_plans, :membership_plan_type, foreign_key: true

    execute <<~SQL.squish
      UPDATE membership_plans
      SET membership_plan_type_id = membership_plan_types.id
      FROM membership_plan_types
      WHERE membership_plan_types.code = CASE membership_plans.plan_type
        WHEN 0 THEN 'membership'
        WHEN 1 THEN 'donation'
        WHEN 2 THEN 'fundraiser'
        ELSE 'other_fee'
      END
    SQL

    change_column_null :membership_plans, :membership_plan_type_id, false
    remove_index :membership_plans, [ :plan_type, :active ]
    remove_column :membership_plans, :plan_type
  end

  def down
    add_column :membership_plans, :plan_type, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE membership_plans
      SET plan_type = CASE membership_plan_types.code
        WHEN 'membership' THEN 0
        WHEN 'donation' THEN 1
        WHEN 'fundraiser' THEN 2
        ELSE 3
      END
      FROM membership_plan_types
      WHERE membership_plans.membership_plan_type_id = membership_plan_types.id
    SQL

    add_index :membership_plans, [ :plan_type, :active ]
    remove_reference :membership_plans, :membership_plan_type, foreign_key: true
    drop_table :membership_plan_types
  end
end
