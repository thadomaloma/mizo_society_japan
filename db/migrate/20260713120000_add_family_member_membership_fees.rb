class AddFamilyMemberMembershipFees < ActiveRecord::Migration[8.1]
  ACTIVE_PAYMENT_STATUSES = "(status = ANY (ARRAY[0, 3, 4, 5, 8]))"

  def up
    add_column :family_members, :membership_number, :string
    add_index :family_members, :membership_number, unique: true, where: "membership_number IS NOT NULL"

    execute <<~SQL.squish
      WITH numbered_children AS (
        SELECT family_members.id,
               member_profiles.membership_number || '-C' ||
                 LPAD(ROW_NUMBER() OVER (
                   PARTITION BY family_members.member_profile_id
                   ORDER BY family_members.created_at, family_members.id
                 )::text, 2, '0') AS generated_number
        FROM family_members
        INNER JOIN member_profiles ON member_profiles.id = family_members.member_profile_id
        WHERE LOWER(family_members.relationship) = 'child'
          AND member_profiles.membership_number IS NOT NULL
      )
      UPDATE family_members
      SET membership_number = numbered_children.generated_number
      FROM numbered_children
      WHERE family_members.id = numbered_children.id
    SQL

    add_column :membership_plans, :child_fee_enabled, :boolean, default: false, null: false
    add_column :membership_plans, :child_amount, :decimal, precision: 10, scale: 2

    add_reference :membership_payments,
      :family_member,
      foreign_key: true,
      index: true
    add_column :membership_payments, :beneficiary_name, :string
    add_column :membership_payments, :beneficiary_membership_number, :string

    remove_index :membership_payments, name: "idx_unique_active_membership_payment_period"
    add_index :membership_payments,
      "user_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)",
      unique: true,
      where: "family_member_id IS NULL AND #{ACTIVE_PAYMENT_STATUSES}",
      name: "idx_unique_guardian_payment_period"
    add_index :membership_payments,
      "family_member_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)",
      unique: true,
      where: "family_member_id IS NOT NULL AND #{ACTIVE_PAYMENT_STATUSES}",
      name: "idx_unique_family_member_payment_period"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Family-member payment records cannot be safely collapsed into guardian-only records."
  end
end
