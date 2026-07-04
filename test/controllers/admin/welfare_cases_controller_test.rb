require "test_helper"

class Admin::WelfareCasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    @secretary = create_user("Secretary User", "secretary_welfare@example.test", :secretary)
    @assistant_secretary = create_user("Assistant Secretary User", "welfare_assistant@example.test", :assistant_secretary)
    @treasurer = create_user("Treasurer User", "welfare_treasurer@example.test", :treasurer)
    @vice_president = create_user("Vice President User", "welfare_vp@example.test", :vice_president)
    @executive_member = create_user("Executive User", "welfare_executive@example.test", :executive_member)
    @category = WelfareCategory.create!(name: "Test Welfare Category", active: true)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08013572468")
    ensure_profile_for(@vice_president, mobile_number: "09086427531")
    ensure_profile_for(@executive_member, mobile_number: "07024681359")
  end

  test "new welfare case only lists eligible officers for assignment" do
    sign_in @president

    get new_admin_welfare_case_path

    assert_response :success
    assert_select "select[name='welfare_case[assigned_to_id]']" do
      assert_select "option", text: @president.display_name
      assert_select "option", text: @secretary.display_name
      assert_select "option", text: @assistant_secretary.display_name
      assert_select "option", text: @treasurer.display_name, count: 0
    end
  end

  test "welfare case accepts assistant secretary as assignee" do
    sign_in @president

    assert_difference -> { WelfareCase.count }, 1 do
      post admin_welfare_cases_path, params: {
        welfare_case: {
          user_id: @member.id,
          welfare_category_id: @category.id,
          title: "Support request",
          description: "A private support request.",
          priority: "medium",
          status: "submitted",
          assigned_to_id: @assistant_secretary.id,
          confidential: "1"
        }
      }
    end

    welfare_case = WelfareCase.last
    assert_redirected_to admin_welfare_case_path(welfare_case)
    assert_equal @assistant_secretary, welfare_case.assigned_to
  end

  test "assignment endpoint accepts assistant secretary" do
    welfare_case = WelfareCase.create!(
      user: @member,
      welfare_category: @category,
      title: "Existing support request",
      description: "A private support request.",
      assigned_to: @secretary
    )
    sign_in @president

    patch assign_admin_welfare_case_path(welfare_case), params: { welfare_case: { assigned_to_id: @assistant_secretary.id } }

    assert_redirected_to admin_welfare_case_path(welfare_case)
    assert_equal @assistant_secretary, welfare_case.reload.assigned_to
  end

  test "executive members can view welfare records but cannot manage them" do
    welfare_case = WelfareCase.create!(
      user: @member,
      welfare_category: @category,
      title: "Executive view case",
      description: "A private support request.",
      assigned_to: @secretary
    )
    sign_in @executive_member

    get admin_welfare_cases_path
    assert_response :success
    assert_includes response.body, welfare_case.title

    get admin_welfare_case_path(welfare_case)
    assert_response :success

    get new_admin_welfare_case_path
    assert_redirected_to root_path

    patch resolve_admin_welfare_case_path(welfare_case)
    assert_redirected_to root_path
  end

  test "vice president can view welfare records but cannot manage them" do
    welfare_case = WelfareCase.create!(
      user: @member,
      welfare_category: @category,
      title: "Vice president view case",
      description: "A private support request.",
      assigned_to: @secretary
    )
    sign_in @vice_president

    get admin_welfare_cases_path
    assert_response :success
    assert_includes response.body, welfare_case.title

    get admin_welfare_case_path(welfare_case)
    assert_response :success

    get new_admin_welfare_case_path
    assert_redirected_to root_path

    patch resolve_admin_welfare_case_path(welfare_case)
    assert_redirected_to root_path
  end

  private

  def create_user(name, email, role)
    User.create!(name: name, email: email, password: "password123", role: role)
  end

  def ensure_profile_for(user, mobile_number: "09024681357")
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
