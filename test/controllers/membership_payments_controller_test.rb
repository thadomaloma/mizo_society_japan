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
    assert_match(/Select Payments.*Optional Payment Plans.*Payment History/m, response.body)
    assert_includes response.body, "0</span> selected"
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
    assert_match(/Select Payments.*#{@payment.membership_plan.name}/m, response.body)
    assert_match(/Payment History.*#{paid_payment.membership_plan.name}/m, response.body)
  end

  test "paid guardian fee does not hide an unpaid child fee for the same plan" do
    child = @member.member_profile.family_members.create!(
      name: "Family Fee Child",
      relationship: "Child",
      date_of_birth: 14.years.ago.to_date
    )
    @payment.update!(status: :paid, paid_on: Time.current)
    child_payment = MembershipPayment.create!(
      user: @member,
      family_member: child,
      membership_plan: @plan,
      amount: 2000,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )

    sign_in @member
    get membership_payments_path

    assert_response :success
    assert_includes response.body, "value=\"#{child_payment.id}\""
    assert_includes response.body, "For Family Fee Child"
  end

  test "settled optional plan hides stale unpaid duplicate from current payments" do
    paid_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :paid,
      paid_on: Time.current
    )
    stale_payment = MembershipPayment.new(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year - 1,
      payment_method: :bank_transfer,
      status: :pending
    )
    stale_payment.save!(validate: false)

    sign_in @member
    get membership_payments_path

    assert_response :success
    assert_match(/Payment History.*#{paid_payment.membership_plan.name}/m, response.body)
    assert_not_includes response.body, "value=\"#{stale_payment.id}\""
    assert_not_includes response.body, "value=\"#{@donation_plan.id}\""
  end

  test "pending combined batch remains visible on payments page" do
    donation_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
    batch = @member.payment_batches.create!(status: :pending)
    @payment.update!(payment_batch: batch)
    donation_payment.update!(payment_batch: batch)
    batch.update!(total_amount: @payment.amount + donation_payment.amount)

    sign_in @member
    get membership_payments_path

    assert_response :success
    assert_includes response.body, "Submitted Combined Payments"
    assert_includes response.body, payment_batch_path(batch)
    assert_not_includes response.body, "value=\"#{@payment.id}\""
    assert_not_includes response.body, "value=\"#{donation_payment.id}\""
  end

  test "member can create combined payment from selected payments without javascript" do
    donation_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )

    sign_in @member

    assert_difference -> { @member.payment_batches.count }, 1 do
      post payment_batches_path, params: { membership_payment_ids: [ @payment.id, donation_payment.id ] }
    end

    batch = @member.payment_batches.order(:id).last
    assert_redirected_to payment_batch_path(batch)
    assert_equal "pending", batch.status
    assert_equal @payment.amount + donation_payment.amount, batch.total_amount
    assert_equal [ @payment.id, donation_payment.id ].sort, batch.membership_payment_ids.sort
  end

  test "member can combine guardian and child fees in one bank transfer" do
    @plan.update!(membership_plan_type: membership_plan_types(:membership))
    child = @member.member_profile.family_members.create!(
      name: "Combined Fee Child",
      relationship: "Child",
      date_of_birth: 14.years.ago.to_date
    )
    child_payment = MembershipPayment.create!(
      user: @member,
      family_member: child,
      membership_plan: @plan,
      amount: 2000,
      payment_year: Date.current.year,
      status: :pending
    )
    sign_in @member

    post payment_batches_path, params: { membership_payment_ids: [ @payment.id, child_payment.id ] }

    batch = @member.payment_batches.order(:id).last
    assert_redirected_to payment_batch_path(batch)
    assert_equal 7000, batch.total_amount
    assert_equal [ @payment.id, child_payment.id ].sort, batch.membership_payment_ids.sort
  end

  test "member can review pending combined payment before submitting transfer" do
    donation_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
    batch = @member.payment_batches.create!(status: :pending)
    @payment.update!(payment_batch: batch)
    donation_payment.update!(payment_batch: batch)
    batch.update!(total_amount: @payment.amount + donation_payment.amount)

    sign_in @member
    get payment_batch_path(batch)

    assert_response :success
    assert_includes response.body, "Combined Payment"
    assert_includes response.body, "Submit Transfer"
    assert_includes response.body, "Change Selection"
    assert_includes response.body, @plan.name
    assert_includes response.body, @donation_plan.name
  end

  test "member can cancel pending combined payment and select again" do
    donation_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
    batch = @member.payment_batches.create!(status: :pending)
    @payment.update!(payment_batch: batch)
    donation_payment.update!(payment_batch: batch)
    batch.update!(total_amount: @payment.amount + donation_payment.amount)

    sign_in @member

    patch cancel_payment_batch_path(batch)

    assert_redirected_to membership_payments_path
    assert_equal "cancelled", batch.reload.status
    assert_nil @payment.reload.payment_batch_id
    assert_nil donation_payment.reload.payment_batch_id

    get membership_payments_path

    assert_response :success
    assert_includes response.body, "value=\"#{@payment.id}\""
    assert_includes response.body, "value=\"#{donation_payment.id}\""
  end

  test "empty combined payment selection redirects back with alert" do
    sign_in @member

    assert_no_difference -> { @member.payment_batches.count } do
      post payment_batches_path, params: { membership_payment_ids: [] }
    end

    assert_redirected_to membership_payments_path
    assert_equal "Select at least one unpaid payment.", flash[:alert]
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

  test "admin payment show uses WhatsApp receipt message without call button" do
    @payment.update!(
      status: :paid,
      paid_on: Time.current,
      approved_by: @president,
      reference_number: "BANK-REF-123"
    )
    sign_in @president

    get admin_membership_payment_path(@payment)

    assert_response :success
    assert_no_match(/>Call</, response.body)
    assert_includes response.body, "WhatsApp"
    assert_includes response.body, "Receipt ready"
    assert_includes response.body, "I sent this receipt"
    assert_includes response.body, "MSJ+Payment+Receipt"
    assert_includes response.body, URI.encode_www_form_component(@payment.receipt_number)
    assert_includes response.body, URI.encode_www_form_component(@plan.name)
    assert_includes response.body, "Confirmed+by"
    assert_includes response.body, receipt_membership_payment_path(@payment)
  end

  test "member can print an approved itemized payment receipt" do
    @payment.update!(
      status: :paid,
      paid_on: Time.zone.local(2026, 7, 14, 10, 30),
      approved_by: @president,
      reference_number: "BANK-2026-001"
    )
    sign_in @member

    get receipt_membership_payment_path(@payment)

    assert_response :success
    assert_select "article.thermal-receipt"
    assert_includes response.body, "Official Payment Receipt"
    assert_includes response.body, @payment.receipt_number
    assert_includes response.body, @member.member_profile.membership_number
    assert_includes response.body, @plan.name
    assert_includes response.body, "¥5,000"
    assert_includes response.body, "BANK-2026-001"
    assert_includes response.body, @president.display_name
    assert_includes response.body, "Print Receipt"
  end

  test "unpaid payment cannot be opened as an official receipt" do
    sign_in @member

    get receipt_membership_payment_path(@payment)

    assert_redirected_to root_path
    assert_equal "You are not authorized to access that area.", flash[:alert]
  end

  test "member can print one receipt for an approved combined payment" do
    donation_payment = MembershipPayment.create!(
      user: @member,
      membership_plan: @donation_plan,
      amount: @donation_plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :paid,
      paid_on: Time.current,
      approved_by: @president
    )
    batch = @member.payment_batches.create!(
      status: :paid,
      total_amount: @payment.amount + donation_payment.amount,
      transfer_reference_name: "COMBINED-REF",
      approved_by: @president,
      approved_at: Time.current
    )
    @payment.update!(status: :paid, paid_on: Time.current, approved_by: @president, payment_batch: batch)
    donation_payment.update!(payment_batch: batch)
    sign_in @member

    get receipt_payment_batch_path(batch)

    assert_response :success
    assert_includes response.body, batch.receipt_number
    assert_includes response.body, @plan.name
    assert_includes response.body, @donation_plan.name
    assert_includes response.body, "¥7,000"
    assert_includes response.body, "COMBINED-REF"

    get membership_payment_path(@payment)

    assert_response :success
    assert_includes response.body, receipt_payment_batch_path(batch)
    assert_not_includes response.body, receipt_membership_payment_path(@payment)
  end

  test "admin payment records show receipt state and can mark receipt sent" do
    @payment.update!(
      status: :paid,
      paid_on: Time.current,
      approved_by: @president
    )
    sign_in @president

    get admin_membership_payments_path(status: "paid")

    assert_response :success
    assert_includes response.body, "Receipt ready"
    assert_includes response.body, mark_receipt_sent_admin_membership_payment_path(@payment)

    patch mark_receipt_sent_admin_membership_payment_path(@payment), headers: { "HTTP_REFERER" => admin_membership_payments_url(status: "paid") }

    assert_redirected_to admin_membership_payments_path(status: "paid")
    assert @payment.reload.receipt_sent?
    assert_equal @president, @payment.receipt_sent_by

    get admin_membership_payments_path(status: "paid")

    assert_response :success
    assert_includes response.body, "Receipt sent"
  end

  test "admin payment records hide prepared combined payments until transfer is submitted" do
    plan = MembershipPlan.create!(
      name: "Prepared Batch Fund",
      amount: 1500,
      membership_plan_type: @donation_plan.membership_plan_type,
      billing_cycle: :one_time,
      active: true
    )
    payment = MembershipPayment.create!(
      user: @member,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending
    )
    batch = @member.payment_batches.create!(status: :pending)
    payment.update!(payment_batch: batch)
    batch.update!(total_amount: payment.amount)

    sign_in @president
    get admin_membership_payments_path

    assert_response :success
    assert_not_includes response.body, "Prepared Batch Fund"
    assert_not_includes response.body, admin_membership_payment_path(payment)
  end

  test "admin payment records show paid payments from approved combined batches" do
    plan = MembershipPlan.create!(
      name: "Approved Batch Fund",
      amount: 2500,
      membership_plan_type: @donation_plan.membership_plan_type,
      billing_cycle: :one_time,
      active: true
    )
    batch = @member.payment_batches.create!(status: :paid, total_amount: plan.amount, approved_by: @president, approved_at: Time.current)
    payment = MembershipPayment.create!(
      user: @member,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: Date.current.year,
      payment_method: :manual_bank_transfer,
      status: :paid,
      paid_on: Time.current,
      approved_by: @president,
      payment_batch: batch
    )

    sign_in @president
    get admin_membership_payments_path(status: "paid")

    assert_response :success
    assert_includes response.body, "Approved Batch Fund"
    assert_includes response.body, admin_membership_payment_path(payment)
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
        date_of_birth: Date.new(1990, 1, 1),
        family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end
end
