require "test_helper"

class PaymentMailerTest < ActionMailer::TestCase
  setup do
    @member = users(:member)
    @president = users(:admin)
    @treasurer = User.create!(
      email: "active_treasurer@example.test",
      name: "Active Treasurer",
      role: :treasurer,
      password: "password123"
    )
    @inactive_finance_secretary = User.create!(
      email: "inactive_finance@example.test",
      name: "Inactive Finance Secretary",
      role: :finance_secretary,
      active: false,
      password: "password123"
    )
    plan = MembershipPlan.create!(
      name: "Mailer Test Fee",
      amount: 5000,
      membership_plan_type: membership_plan_types(:membership),
      billing_cycle: :yearly,
      active: true
    )
    @batch = @member.payment_batches.create!(
      status: :pending_verification,
      total_amount: plan.amount,
      transfer_amount: plan.amount,
      transferred_on: Date.current,
      transfer_reference_name: "MEMBER USER"
    )
    MembershipPayment.create!(
      user: @member,
      membership_plan: plan,
      payment_batch: @batch,
      amount: plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :pending_verification
    )
  end

  test "combined transfer submission is sent only to active finance recipients" do
    mail = PaymentMailer.with(payment_batch: @batch).batch_transfer_submitted

    assert_equal "MSJ combined payment pending verification", mail.subject
    assert_equal [ @president.email, @treasurer.email ].sort, mail.to.sort
    assert_not_includes mail.to, @inactive_finance_secretary.email
    assert_includes mail.text_part.body.to_s, "MEMBER USER"
    assert_includes mail.text_part.body.to_s, "¥5,000"
  end

  test "combined payment decision emails are sent to the member" do
    approved_mail = PaymentMailer.with(payment_batch: @batch).batch_approved
    rejected_mail = PaymentMailer.with(payment_batch: @batch).batch_rejected

    assert_equal [ @member.email ], approved_mail.to
    assert_equal "MSJ combined payment approved", approved_mail.subject
    assert_includes approved_mail.text_part.body.to_s, "¥5,000"

    assert_equal [ @member.email ], rejected_mail.to
    assert_equal "MSJ combined payment needs review", rejected_mail.subject
    assert_includes rejected_mail.text_part.body.to_s, "could not be verified"
  end
end
