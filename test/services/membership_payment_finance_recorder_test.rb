require "test_helper"

class MembershipPaymentFinanceRecorderTest < ActiveSupport::TestCase
  setup do
    @member = users(:member)
    @approver = users(:admin)
    @plan_type = membership_plan_types(:membership)
    @donation_type = membership_plan_types(:donation)
  end

  test "approving a membership payment creates an approved income transaction" do
    payment = create_payment(plan: create_plan("Recorder Annual Fee", @plan_type, 5000))

    assert_difference -> { FinanceTransaction.approved.income.count }, 1 do
      payment.approve!(@approver)
    end

    transaction = FinanceTransaction.find_by!(reference_number: "membership-payment-#{payment.id}")
    assert_equal "Membership Fee", transaction.finance_category.name
    assert_equal payment.amount, transaction.amount
    assert_equal @approver, transaction.recorded_by
    assert_equal @approver, transaction.approved_by
  end

  test "approving a combined payment creates one transaction per included payment" do
    first_payment = create_payment(plan: create_plan("Recorder Chhiatni Fund", @donation_type, 2000))
    second_payment = create_payment(plan: create_plan("Recorder Relief Fund", @donation_type, 3000))
    batch = PaymentBatch.create!(user: @member, status: :pending_verification, total_amount: 5000)
    [ first_payment, second_payment ].each do |payment|
      payment.update!(
        payment_batch: batch,
        status: :pending_verification,
        payment_method: :manual_bank_transfer,
        transfer_reference_name: "SAME BANK REF"
      )
    end

    assert_difference -> { FinanceTransaction.approved.income.count }, 2 do
      batch.approve!(@approver)
    end

    assert FinanceTransaction.exists?(reference_number: "membership-payment-#{first_payment.id}")
    assert FinanceTransaction.exists?(reference_number: "membership-payment-#{second_payment.id}")
  end

  test "shared legacy transfer reference is adopted once during backfill" do
    first_payment = paid_payment(plan: create_plan("Legacy Chhiatni Fund", @donation_type, 2000), reference: "OLD SHARED REF")
    second_payment = paid_payment(plan: create_plan("Legacy Relief Fund", @donation_type, 3000), reference: "OLD SHARED REF")
    category = FinanceCategory.create!(name: "Legacy Donation", category_type: :income, active: true)
    FinanceTransaction.create!(
      finance_category: category,
      recorded_by: @approver,
      transaction_type: :income,
      amount: 2000,
      transaction_date: Date.current,
      status: :approved,
      reference_number: "OLD SHARED REF"
    )

    assert_difference -> { FinanceTransaction.count }, 1 do
      [ first_payment, second_payment ].each do |payment|
        MembershipPaymentFinanceRecorder.call(payment: payment, actor: @approver)
      end
    end

    assert FinanceTransaction.exists?(reference_number: "membership-payment-#{first_payment.id}")
    assert FinanceTransaction.exists?(reference_number: "membership-payment-#{second_payment.id}")
    assert_not FinanceTransaction.exists?(reference_number: "OLD SHARED REF")
  end

  private

  def create_plan(name, plan_type, amount)
    MembershipPlan.create!(
      name: name,
      membership_plan_type: plan_type,
      amount: amount,
      billing_cycle: :yearly,
      active: true
    )
  end

  def create_payment(plan:)
    MembershipPayment.create!(
      user: @member,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
  end

  def paid_payment(plan:, reference:)
    MembershipPayment.create!(
      user: @member,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :paid,
      paid_on: Time.current,
      approved_by: @approver,
      transfer_reference_name: reference,
      reference_number: reference
    )
  end
end
