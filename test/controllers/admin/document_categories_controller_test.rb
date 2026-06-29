require "test_helper"

class Admin::DocumentCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "content administrator can create a document category" do
    sign_in @president

    assert_difference -> { DocumentCategory.count }, 1 do
      post admin_document_categories_path, params: { document_category: { name: "Community Guides", position: 10, active: "1" } }
    end

    assert_redirected_to admin_document_categories_path
    assert DocumentCategory.find_by!(name: "Community Guides").active?
  end

  test "members cannot manage document categories" do
    sign_in @member

    get admin_document_categories_path

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
