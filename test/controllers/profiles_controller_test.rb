require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @member.member_profile&.destroy!
  end

  test "incomplete member is redirected to profile setup before dashboard" do
    sign_in @member

    get root_path

    assert_redirected_to setup_profile_path
  end

  test "member can complete profile setup" do
    sign_in @member

    patch complete_setup_profile_path, params: {
      member_profile: {
        full_name: "Complete Member",
        mobile_number: "09012345678",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo"
      }
    }

    assert_redirected_to root_path
    assert @member.reload.profile_complete?
    assert_equal "MSJ-#{Date.current.year}-0001", @member.member_profile.membership_number
  end

  test "member can save family profile details with children" do
    sign_in @member

    patch complete_setup_profile_path, params: {
      member_profile: {
        full_name: "Family Member",
        mobile_number: "09012345678",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo",
        father_name: "Father Name",
        mother_name: "Mother Name",
        family_status: "family",
        spouse_name: "Spouse Name",
        family_members_attributes: {
          "0" => { name: "Child One", relationship: "Child" },
          "1" => { name: "Child Two", relationship: "Child" }
        }
      }
    }

    assert_redirected_to root_path
    profile = @member.reload.member_profile
    assert_equal "Father Name", profile.father_name
    assert_equal "Mother Name", profile.mother_name
    assert_equal "family", profile.family_status
    assert_equal "Spouse Name", profile.spouse_name
    assert_equal [ "Child One", "Child Two" ], profile.child_family_members.order(:name).pluck(:name)
  end

  test "member profile shows map but hides admin contact actions" do
    @member.create_member_profile!(
      full_name: "Complete Member",
      mobile_number: "09012345678",
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
    sign_in @member

    get profile_path

    assert_response :success
    assert_includes response.body, "Okubo"
    assert_includes response.body, "Google Map"
    assert_includes response.body, "google.com/maps"
    assert_no_match(/>Call</, response.body)
    assert_no_match(/>WhatsApp</, response.body)
  end
end
