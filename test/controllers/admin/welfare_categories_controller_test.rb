require "test_helper"

class Admin::WelfareCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "welfare manager can create and edit a welfare category" do
    sign_in @president

    assert_difference -> { WelfareCategory.count }, 1 do
      post admin_welfare_categories_path, params: {
        welfare_category: {
          name: "Family Support",
          description: "Support for family needs.",
          active: "1"
        }
      }
    end

    category = WelfareCategory.find_by!(name: "Family Support")
    assert_redirected_to admin_welfare_categories_path

    patch admin_welfare_category_path(category), params: {
      welfare_category: {
        name: "Emergency Family Support",
        description: "Updated guidance.",
        active: "0"
      }
    }

    assert_redirected_to admin_welfare_categories_path
    assert_equal "Emergency Family Support", category.reload.name
    assert_equal "Updated guidance.", category.description
    assert_not category.active?
  end

  test "category used by welfare cases cannot be deleted" do
    category = WelfareCategory.create!(name: "Protected Welfare Category", active: true)
    WelfareCase.create!(
      user: @member,
      welfare_category: category,
      title: "Protected case",
      description: "A case that protects its category.",
      priority: :medium,
      status: :submitted
    )
    sign_in @president

    assert_no_difference -> { WelfareCategory.count } do
      delete admin_welfare_category_path(category)
    end

    assert_redirected_to admin_welfare_categories_path
    assert_equal "This category is used by welfare cases and cannot be deleted.", flash[:alert]
  end

  test "members cannot manage welfare categories" do
    sign_in @member

    get admin_welfare_categories_path

    assert_redirected_to root_path
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
