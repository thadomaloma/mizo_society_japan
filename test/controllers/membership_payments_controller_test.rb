require "test_helper"
class MembershipPaymentsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @member = users(:member)
    @president = users(:admin)
    ensure_profile_for(@member)
    ensure_profile_for(@president, mobile_number: "08013572468")
    @plan = MembershipPlan.create!(
      name: "Test Annual Member Fee",
      amount: 5000,
      membership_plan_type: MembershipPlanType.find_by!(code: "membership"),
      billing_cycle: :yearly,
      active: true
    )
    @donation_plan = MembershipPlan.create!(
      name: "Emergency Relief Donation",
      amount: 2000,
      membership_plan_type: MembershipPlanType.find_by!(code: "donation"),
      billing_cycle: :one_time,
      active: true,
      description: "Support the emergency relief fund."
    )
    @payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @plan,
      amount: @plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
  end

  test "member without a payment gets current year fee on My Payments" do
    new_member = User.create!(
      email: "new_member@example.test",
      name: "New Member",
      role: :member,
      password: "password123"
    )
    ensure_profile_for(new_member, mobile_number: "08013572469")

    sign_in new_member

    assert_difference -> { new_member.membership_payments.count }, 1 do
      get membership_payments_path
    end

    payment = new_member.membership_payments.last
    assert_response :success
    assert_equal @plan, payment.membership_plan
    assert_equal Date.current.year, payment.payment_year
    assert_equal "pending", payment.status
    assert_includes response.body, @plan.name
    assert_includes response.body, "Pay Together"
    assert_match(/Current Payments.*Optional Payment Plans.*Payment History/m, response.body)
  end

  test "office bearer without a payment gets required fees on My Payments" do
    assistant_secretary = User.create!(
      email: "assistant_payment@example.test",
      name: "Assistant Payment",
      role: :assistant_secretary,
      password: "password123"
    )
    ensure_profile_for(assistant_secretary, mobile_number: "07024681350")
    required_plan = MembershipPlan.create!(
      name: "Required OB Society Fee",
      amount: 3000,
      membership_plan_type: MembershipPlanType.find_by!(code: "other_fee"),
      billing_cycle: :yearly,
      active: true,
      required_for_members: true
    )

    sign_in assistant_secretary

    assert_difference -> { assistant_secretary.membership_payments.where(membership_plan: required_plan).count }, 1 do
      get membership_payments_path
    end

    payment = assistant_secretary.membership_payments.find_by!(membership_plan: required_plan)
    assert_response :success
    assert_equal "pending", payment.status
    assert_includes response.body, required_plan.name
    assert_includes response.body, "Pay Together"
  end

  test "current payments and payment history are separated" do
    paid_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :paid,
      paid_on: Time.current
    )

    sign_in @member
    get membership_payments_path

    assert_response :success
    assert_match(/Current Payments.*#{@payment.membership_plan.name}/m, response.body)
    assert_match(/Payment History.*#{paid_payment.membership_plan.name}/m, response.body)
  end

  test "member can submit bank transfer details for treasurer verification" do
    sign_in @member

    assert_enqueued_emails 1 do
      assert_difference -> { Notification.payment_submitted.count }, User.where(role: User::FINANCE_ROLES).count do
        patch submit_transfer_membership_payment_path(@payment), params: {
          membership_payment: {
            transferred_on: Date.current,
            transfer_amount: "5000",
            transfer_reference_name: "MEMBER USER"
          }
        }
      end
    end

    assert_redirected_to membership_payment_path(@payment)
    @payment.reload
    assert_equal "pending_verification", @payment.status
    assert_equal "manual_bank_transfer", @payment.payment_method
    assert_equal Date.current, @payment.transferred_on
    assert_equal BigDecimal("5000"), @payment.transfer_amount
    assert_equal "MEMBER USER", @payment.transfer_reference_name
  end

  test "member can start an optional donation plan without creating duplicate pending payments" do
    sign_in @member

    assert_difference -> { @member.membership_payments.count }, 1 do
      post start_membership_payments_path, params: { membership_plan_id: @donation_plan.id }
    end

    payment = @member.membership_payments.order(:id).last
    assert_redirected_to membership_payment_path(payment)
    assert_equal @donation_plan, payment.membership_plan
    assert_equal "One-time payment", payment.period_label
    assert_equal "Donation", payment.plan_type_label

    assert_no_difference -> { @member.membership_payments.count } do
      post start_membership_payments_path, params: { membership_plan_id: @donation_plan.id }
    end
    assert_redirected_to membership_payment_path(payment)

    get membership_payments_path
    assert_response :success
    assert_not_includes response.body, "Optional Payment Plans"
  end

  test "optional payments do not prevent the annual membership fee from being provisioned" do
    new_member = User.create!(
      email: "donation_member@example.test",
      name: "Donation Member",
      role: :member,
      password: "password123"
    )
    ensure_profile_for(new_member, mobile_number: "07024681379")
    MembershipPayment.create!(
      user: new_member,
      membership_plan: @donation_plan,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )

    sign_in new_member

    assert_difference -> { new_member.membership_payments.membership_dues.count }, 1 do
      get membership_payments_path
    end

    assert_equal @plan, new_member.membership_payments.membership_dues.last.membership_plan
  end

  test "Add Payment button uses the new admin payment route without query parameters" do
    sign_in @president

    get admin_membership_payments_path

    assert_response :success
    assert_select "a[href='#{new_admin_membership_payment_path}']", text: "Add Payment"
    assert_not_includes response.body, "#{admin_membership_payments_path}?class="
  end

  test "admin can select an active donation plan for a manual payment" do
    sign_in @president

    get new_admin_membership_payment_path

    assert_response :success
    assert_select "option[value='#{@donation_plan.id}']", text: /Emergency Relief Donation/
  end

  test "member cannot open the admin membership payments page" do
    sign_in @member

    get admin_membership_payments_path

    assert_redirected_to root_path
  end

  private

  def ensure_profile_for(user, mobile_number: "09024681357")
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
