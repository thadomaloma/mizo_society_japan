require "test_helper"

class MembershipPaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
    ensure_profile_for(@user)
    @plan_type = MembershipPlanType.create!(name: "Test Fee", code: "test_fee")
    @yearly_plan = MembershipPlan.create!(
      name: "Annual Test Fee",
      membership_plan_type: @plan_type,
      amount: 5000,
      billing_cycle: :yearly,
      active: true
    )
    @one_time_plan = MembershipPlan.create!(
      name: "One Time Test Fund",
      membership_plan_type: @plan_type,
      amount: 2000,
      billing_cycle: :one_time,
      active: true
    )
    @monthly_plan = MembershipPlan.create!(
      name: "Monthly Test Fee",
      membership_plan_type: @plan_type,
      amount: 1000,
      billing_cycle: :monthly,
      active: true
    )
  end

  test "blocks duplicate active payment for same member plan and period" do
    create_payment(@yearly_plan, payment_year: 2026, status: :paid)
    duplicate = build_payment(@yearly_plan, payment_year: 2026, status: :pending)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base].join, @user.member_profile.membership_number
    assert_includes duplicate.errors[:base].join, "already has an active or paid Annual Test Fee record"
  end

  test "allows same yearly plan for a different year" do
    create_payment(@yearly_plan, payment_year: 2026, status: :paid)
    next_year = build_payment(@yearly_plan, payment_year: 2027, status: :pending)

    assert next_year.valid?
  end

  test "blocks duplicate one time payment across years" do
    create_payment(@one_time_plan, payment_year: 2026, status: :paid)
    duplicate = build_payment(@one_time_plan, payment_year: 2027, status: :pending)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base].join, @user.member_profile.membership_number
    assert_includes duplicate.errors[:base].join, "already has an active or paid One Time Test Fund record"
  end

  test "cancelled records do not block a replacement payment" do
    create_payment(@yearly_plan, payment_year: 2026, status: :cancelled)
    replacement = build_payment(@yearly_plan, payment_year: 2026, status: :pending)

    assert replacement.valid?
  end

  test "blank month admin record is blocked by existing same year monthly payment" do
    create_payment(@monthly_plan, payment_year: 2026, payment_month: 7, status: :pending_verification)
    duplicate = build_payment(@monthly_plan, payment_year: 2026, status: :pending)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base].join, @user.member_profile.membership_number
    assert_includes duplicate.errors[:base].join, "already has an active or paid Monthly Test Fee record"
  end

  private

  def ensure_profile_for(user)
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: "09055556666",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end

  def create_payment(plan, payment_year:, status:, payment_month: nil)
    build_payment(plan, payment_year: payment_year, status: status, payment_month: payment_month).tap(&:save!)
  end

  def build_payment(plan, payment_year:, status:, payment_month: nil)
    MembershipPayment.new(
      user: @user,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: payment_year,
      payment_month: payment_month,
      payment_method: :bank_transfer,
      status: status
    )
  end
end
