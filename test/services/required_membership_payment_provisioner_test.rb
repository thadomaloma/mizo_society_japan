require "test_helper"

class RequiredMembershipPaymentProvisionerTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
    @profile = @user.member_profile || @user.create_member_profile!(
      full_name: "Provisioning Member",
      mobile_number: "07024681358",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :family,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
    @profile.update!(family_status: :family)
    @plan = MembershipPlan.create!(
      name: "Child Provisioning Membership Fee",
      amount: 5000,
      child_fee_enabled: true,
      child_amount: 2000,
      membership_plan_type: membership_plan_types(:membership),
      billing_cycle: :yearly,
      active: true,
      required_for_members: true
    )
  end

  test "creates guardian and eligible child payments under one user account" do
    eligible_child = @profile.family_members.create!(
      name: "Older Child",
      relationship: "Child",
      date_of_birth: 14.years.ago.to_date
    )
    @profile.family_members.create!(
      name: "Younger Child",
      relationship: "Child",
      date_of_birth: 13.years.ago.to_date
    )

    assert_difference -> { @user.membership_payments.where(membership_plan: @plan).count }, 2 do
      RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    end

    guardian_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member_id: nil)
    child_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: eligible_child)

    assert_equal 5000, guardian_payment.amount
    assert_equal 2000, child_payment.amount
    assert_equal eligible_child.name, child_payment.beneficiary_name
    assert_equal eligible_child.membership_number, child_payment.beneficiary_membership_number
  end

  test "reuses child payment and syncs its pending amount" do
    child = @profile.family_members.create!(
      name: "Older Child",
      relationship: "Child",
      date_of_birth: 15.years.ago.to_date
    )
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    child_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: child)
    @plan.update!(child_amount: 2500)

    assert_no_difference -> { @user.membership_payments.where(membership_plan: @plan).count } do
      RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    end

    assert_equal 2500, child_payment.reload.amount
  end
end
