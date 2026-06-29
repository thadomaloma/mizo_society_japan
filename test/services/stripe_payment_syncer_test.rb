require "test_helper"
require "ostruct"

class StripePaymentSyncerTest < ActiveSupport::TestCase
  setup do
    @member = users(:member)
    @finance_user = users(:admin)
    ensure_profile_for(@member)
    ensure_profile_for(@finance_user, mobile_number: "08012345678")
    @plan = MembershipPlan.create!(
      name: "Online Annual Fee",
      amount: 5000,
      membership_plan_type: MembershipPlanType.find_by!(code: "membership"),
      billing_cycle: :yearly,
      active: true
    )
    @payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @plan,
      amount: @plan.amount,
      payment_year: Date.current.year,
      payment_method: :online_card,
      status: :pending,
      stripe_checkout_session_id: "cs_test_paid",
      stripe_payment_intent_id: "pi_test_paid",
      stripe_customer_id: "cus_test_paid"
    )
  end

  test "payment intent succeeded marks payment paid and records finance transaction" do
    payment_intent = OpenStruct.new(
      id: "pi_test_paid",
      customer: "cus_test_paid",
      status: "succeeded",
      payment_method_types: [ "card" ],
      payment_method_options: nil,
      metadata: OpenStruct.new(membership_payment_id: @payment.id)
    )
    event = OpenStruct.new(type: "payment_intent.succeeded", data: OpenStruct.new(object: payment_intent))

    assert_difference -> { FinanceTransaction.count }, 1 do
      assert_difference -> { Notification.payment_approved.count }, 1 do
        assert_difference -> { AuditLog.where(action: "online_payment_paid").count }, 1 do
          StripePaymentSyncer.call(event: event)
        end
      end
    end

    @payment.reload
    assert_equal "paid", @payment.status
    assert_equal "online_card", @payment.payment_method
    assert_equal "card", @payment.stripe_payment_method_type
    assert @payment.paid_on.present?

    transaction = FinanceTransaction.find_by!(reference_number: "pi_test_paid")
    assert_equal "approved", transaction.status
    assert_equal "income", transaction.transaction_type
    assert_equal @payment.amount, transaction.amount
  end

  test "expired checkout session marks unpaid payment expired" do
    session = OpenStruct.new(
      id: "cs_test_paid",
      status: "expired",
      expires_at: Time.current.to_i,
      metadata: OpenStruct.new(membership_payment_id: @payment.id)
    )
    event = OpenStruct.new(type: "checkout.session.expired", data: OpenStruct.new(object: session))

    StripePaymentSyncer.call(event: event)

    assert_equal "expired", @payment.reload.status
    assert_equal "expired", @payment.stripe_status
  end

  private

  def ensure_profile_for(user, mobile_number: "09012345678")
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: mobile_number,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end
end
