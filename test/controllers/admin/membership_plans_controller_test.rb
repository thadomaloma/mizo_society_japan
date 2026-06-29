require "test_helper"

class Admin::MembershipPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "finance administrator can create a donation plan" do
    sign_in @president
    donation_type = plan_type("donation")

    assert_difference -> { MembershipPlan.where(membership_plan_type: donation_type).count }, 1 do
      post admin_membership_plans_path, params: {
        membership_plan: {
          name: "Community Relief Donation",
          amount: 1000,
          membership_plan_type_id: donation_type.id,
          billing_cycle: "one_time",
          active: "1",
          description: "Optional support for community relief work."
        }
      }
    end

    plan = MembershipPlan.where(membership_plan_type: donation_type).last
    assert_redirected_to admin_membership_plan_path(plan)
    assert_equal "one_time", plan.billing_cycle
  end

  test "plan type filter only returns the requested plans" do
    membership_type = plan_type("membership")
    donation_type = plan_type("donation")
    MembershipPlan.create!(name: "Annual Membership Dues", amount: 5000, membership_plan_type: membership_type, billing_cycle: :yearly, active: true)
    donation = MembershipPlan.create!(name: "Church Visit Donation", amount: 2000, membership_plan_type: donation_type, billing_cycle: :one_time, active: true)
    sign_in @president

    get admin_membership_plans_path(plan_type_id: donation_type.id)

    assert_response :success
    assert_includes response.body, donation.name
    assert_not_includes response.body, "Annual Membership Dues"
  end

  test "members cannot access payment plans" do
    sign_in @member

    get admin_membership_plans_path

    assert_redirected_to root_path
  end

  test "vice president can view payment plans but cannot create or edit" do
    vice_president = User.create!(name: "Vice President", email: "vp_plans@example.test", password: "password123", role: :vice_president)
    ensure_profile_for(vice_president)
    plan = MembershipPlan.create!(name: "Observer Plan", amount: 1000, membership_plan_type: plan_type("other_fee"), billing_cycle: :one_time, active: true)
    sign_in vice_president

    get admin_membership_plans_path
    assert_response :success
    assert_includes response.body, plan.name
    assert_not_includes response.body, "New Plan"

    get new_admin_membership_plan_path
    assert_redirected_to root_path

    get edit_admin_membership_plan_path(plan)
    assert_redirected_to root_path
  end

  test "super admin can delete an unused payment plan" do
    plan = MembershipPlan.create!(name: "One-time Event Fee", amount: 1000, membership_plan_type: plan_type("other_fee"), billing_cycle: :one_time, active: true)
    sign_in @president

    assert_difference -> { MembershipPlan.count }, -1 do
      delete admin_membership_plan_path(plan)
    end

    assert_redirected_to admin_membership_plans_path
    assert_equal "Payment plan was deleted.", flash[:notice]
  end

  test "payment plan with records cannot be deleted" do
    plan = MembershipPlan.create!(name: "Recorded Membership Fee", amount: 5000, membership_plan_type: plan_type("membership"), billing_cycle: :yearly, active: true)
    MembershipPayment.create!(user: @member, membership_plan: plan, payment_year: Date.current.year)
    sign_in @president

    assert_no_difference -> { MembershipPlan.count } do
      delete admin_membership_plan_path(plan)
    end

    assert_redirected_to admin_membership_plans_path
    assert_equal "This plan has payment records and cannot be deleted.", flash[:alert]
  end

  test "payment plans require whole yen amounts" do
    sign_in @president

    assert_no_difference -> { MembershipPlan.count } do
      post admin_membership_plans_path, params: {
        membership_plan: {
          name: "Invalid Decimal Plan",
          amount: "1000.50",
          membership_plan_type_id: plan_type("other_fee").id,
          billing_cycle: "one_time",
          active: "1"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Amount must be an integer"
  end

  test "required payment plan is provisioned for member current payments" do
    sign_in @president
    donation_type = plan_type("donation")

    assert_difference -> { @member.membership_payments.count }, 1 do
      post admin_membership_plans_path, params: {
        membership_plan: {
          name: "Required Community Fee",
          amount: 1500,
          membership_plan_type_id: donation_type.id,
          billing_cycle: "yearly",
          active: "1",
          required_for_members: "1"
        }
      }
    end

    payment = @member.membership_payments.last
    assert_equal "Required Community Fee", payment.membership_plan.name
    assert_equal "pending", payment.status
    assert_equal 1500, payment.amount.to_i
  end

  test "updating required payment plan syncs open member payment amount" do
    plan = MembershipPlan.create!(
      name: "Required Society Fee",
      amount: 1000,
      membership_plan_type: plan_type("other_fee"),
      billing_cycle: :yearly,
      active: true,
      required_for_members: true
    )
    payment = MembershipPayment.create!(user: @member, membership_plan: plan, amount: 1000, payment_year: Date.current.year)
    sign_in @president

    patch admin_membership_plan_path(plan), params: {
      membership_plan: {
        name: plan.name,
        amount: 2000,
        membership_plan_type_id: plan.membership_plan_type_id,
        billing_cycle: plan.billing_cycle,
        active: "1",
        required_for_members: "1"
      }
    }

    assert_redirected_to admin_membership_plan_path(plan)
    assert_equal 2000, payment.reload.amount.to_i
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

  def plan_type(code)
    MembershipPlanType.find_by!(code: code)
  end
end
