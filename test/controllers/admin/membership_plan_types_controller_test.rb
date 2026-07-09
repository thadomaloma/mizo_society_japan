require "test_helper"

class Admin::MembershipPlanTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08013572468")
  end

  test "finance administrator can create a plan type" do
    sign_in @president

    assert_difference -> { MembershipPlanType.count }, 1 do
      post admin_membership_plan_types_path, params: {
        membership_plan_type: { name: "Event Registration", active: "1" }
      }
    end

    plan_type = MembershipPlanType.find_by!(name: "Event Registration")
    assert_redirected_to admin_membership_plan_types_path
    assert_equal "event_registration", plan_type.code
  end

  test "type used by plans cannot be deleted" do
    plan_type = MembershipPlanType.create!(name: "Protected Custom Type", active: true)
    MembershipPlan.create!(name: "Protected Type Plan", amount: 5000, membership_plan_type: plan_type, billing_cycle: :yearly, active: true)
    sign_in @president

    assert_no_difference -> { MembershipPlanType.count } do
      delete admin_membership_plan_type_path(plan_type)
    end

    assert_redirected_to admin_membership_plan_types_path
    assert_equal "This type is used by payment plans and cannot be deleted.", flash[:alert]
  end

  test "default plan types cannot be deleted" do
    plan_type = MembershipPlanType.find_by!(code: "donation")
    sign_in @president

    assert_no_difference -> { MembershipPlanType.count } do
      delete admin_membership_plan_type_path(plan_type)
    end

    assert_redirected_to admin_membership_plan_types_path
    assert_equal "Default plan types cannot be deleted.", flash[:alert]
  end

  test "members cannot manage plan types" do
    sign_in @member

    get admin_membership_plan_types_path

    assert_redirected_to root_path
  end

  private

  def ensure_profile_for(user, mobile_number: "09024681357")
    return if user.member_profile.present?

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
