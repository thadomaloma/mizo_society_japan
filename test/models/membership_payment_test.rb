require "test_helper"

class MembershipPaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
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
  end

  test "blocks duplicate active payment for same member plan and period" do
    create_payment(@yearly_plan, payment_year: 2026, status: :paid)
    duplicate = build_payment(@yearly_plan, payment_year: 2026, status: :pending)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base].join, "already has an active or paid payment record"
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
    assert_includes duplicate.errors[:base].join, "already has an active or paid payment record"
  end

  test "cancelled records do not block a replacement payment" do
    create_payment(@yearly_plan, payment_year: 2026, status: :cancelled)
    replacement = build_payment(@yearly_plan, payment_year: 2026, status: :pending)

    assert replacement.valid?
  end

  private

  def create_payment(plan, payment_year:, status:)
    build_payment(plan, payment_year: payment_year, status: status).tap(&:save!)
  end

  def build_payment(plan, payment_year:, status:)
    MembershipPayment.new(
      user: @user,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: payment_year,
      payment_method: :bank_transfer,
      status: status
    )
  end
end
