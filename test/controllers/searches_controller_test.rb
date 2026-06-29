require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:member)
    ensure_profile_for(@admin)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "signed in users can request global search results in a turbo frame" do
    sign_in @admin

    get global_search_path(q: "Member"), headers: { "Turbo-Frame" => "global_search_results" }

    assert_response :success
    assert_includes response.body, "global_search_results"
  end

  test "members cannot receive member directory results" do
    results = GlobalSearch.call(user: @member, query: @admin.member_profile.full_name)

    assert_not results.any? { |section| section.key == :members }
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
