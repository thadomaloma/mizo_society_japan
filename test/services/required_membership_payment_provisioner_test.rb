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
      date_of_birth: 18.years.ago.to_date
    )
    @profile.family_members.create!(
      name: "Younger Child",
      relationship: "Child",
      date_of_birth: 17.years.ago.to_date
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
      date_of_birth: 19.years.ago.to_date
    )
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    child_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: child)
    @plan.update!(child_amount: 2500)

    assert_no_difference -> { @user.membership_payments.where(membership_plan: @plan).count } do
      RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    end

    assert_equal 2500, child_payment.reload.amount
  end

  test "syncing a plan amount also updates an open combined payment total" do
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    guardian_payment = @user.membership_payments.find_by!(
      membership_plan: @plan,
      family_member_id: nil
    )
    batch = PaymentBatch.create!(user: @user, status: :pending)
    guardian_payment.update!(payment_batch: batch)
    batch.update!(total_amount: guardian_payment.amount)
    @plan.update!(amount: 6500)

    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)

    assert_equal 6500, guardian_payment.reload.amount
    assert_equal 6500, batch.reload.total_amount
  end

  test "retires unpaid child fees below eighteen but preserves reviewed financial records" do
    pending_child = @profile.family_members.create!(
      name: "Pending Child",
      relationship: "Child",
      date_of_birth: 18.years.ago.to_date
    )
    paid_child = @profile.family_members.create!(
      name: "Paid Child",
      relationship: "Child",
      date_of_birth: 18.years.ago.to_date
    )
    review_child = @profile.family_members.create!(
      name: "Review Child",
      relationship: "Child",
      date_of_birth: 18.years.ago.to_date
    )
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)

    pending_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: pending_child)
    paid_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: paid_child)
    review_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: review_child)
    paid_payment.update!(status: :paid, paid_on: Time.current)
    review_payment.update!(status: :pending_verification)
    [ pending_child, paid_child, review_child ].each do |child|
      child.update!(date_of_birth: 17.years.ago.to_date)
    end

    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)

    assert pending_payment.reload.cancelled?
    assert_includes pending_payment.notes, "child fees start at age 18"
    assert paid_payment.reload.paid?
    assert review_payment.reload.pending_verification?

    pending_child.update!(date_of_birth: 18.years.ago.to_date)
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)

    assert pending_payment.reload.pending?
    assert_includes pending_payment.notes, "child reached age 18"
  end

  test "creates a separate spouse membership payment under the family account" do
    @profile.update!(spouse_name: "Provisioning Spouse")

    assert_difference -> { @user.membership_payments.where(membership_plan: @plan).count }, 2 do
      RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    end

    spouse = @profile.reload.spouse_family_member
    spouse_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: spouse)
    assert_equal @plan.amount, spouse_payment.amount
    assert_equal "Provisioning Spouse", spouse_payment.beneficiary_name
    assert_equal spouse.membership_number, spouse_payment.beneficiary_membership_number
  end

  test "removes an ineligible child fee from an unsubmitted payment batch" do
    child = @profile.family_members.create!(
      name: "Batched Child",
      relationship: "Child",
      date_of_birth: 18.years.ago.to_date
    )
    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)
    child_payment = @user.membership_payments.find_by!(membership_plan: @plan, family_member: child)
    batch = PaymentBatch.create!(user: @user, total_amount: child_payment.amount, status: :pending)
    child_payment.update!(payment_batch: batch)
    child.update!(date_of_birth: 17.years.ago.to_date)

    RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: @plan)

    assert child_payment.reload.cancelled?
    assert_nil child_payment.payment_batch_id
    assert batch.reload.cancelled?
    assert_equal 0, batch.total_amount
  end

  test "creates spouse fundraiser payment but does not charge children for the fund" do
    @profile.update!(spouse_name: "Fund Spouse")
    child = @profile.family_members.create!(
      name: "Fund Child",
      relationship: "Child",
      date_of_birth: 19.years.ago.to_date
    )
    fund = MembershipPlan.create!(
      name: "Spouse Provisioning Fund",
      amount: 3000,
      membership_plan_type: membership_plan_types(:fundraiser),
      billing_cycle: :yearly,
      active: true,
      required_for_members: true
    )

    assert_difference -> { @user.membership_payments.where(membership_plan: fund).count }, 2 do
      RequiredMembershipPaymentProvisioner.call(user: @user, membership_plan: fund)
    end

    spouse = @profile.reload.spouse_family_member
    assert @user.membership_payments.exists?(membership_plan: fund, family_member: spouse, amount: 3000)
    assert_not @user.membership_payments.exists?(membership_plan: fund, family_member: child)
  end
end
