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

  test "profile setup uses simple year month and day selectors for date of birth" do
    sign_in @member

    get setup_profile_path

    assert_response :success
    assert_select "select#member_profile_date_of_birth_1i[required]"
    assert_select "select#member_profile_date_of_birth_2i[required]"
    assert_select "select#member_profile_date_of_birth_3i[required]"
    assert_select "input#member_profile_date_of_birth[type=date]", count: 0
    assert_select "template select[id$='_date_of_birth_1i']", count: 1
    assert_select "template select[id$='_date_of_birth_2i']", count: 1
    assert_select "template select[id$='_date_of_birth_3i']", count: 1
    assert_select "template input[id$='_date_of_birth']", count: 0
  end

  test "member can complete profile setup" do
    sign_in @member

    patch complete_setup_profile_path, params: {
      member_profile: {
        full_name: "Complete Member",
        mobile_number: "09024681357",
        date_of_birth: "1990-01-01",
        family_status: "single",
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
        mobile_number: "09024681357",
        date_of_birth: "1990-01-01",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo",
        father_name: "Father Name",
        mother_name: "Mother Name",
        family_status: "family",
        spouse_name: "Spouse Name",
        family_members_attributes: {
          "0" => { name: "Child One", date_of_birth: "2010-05-01", relationship: "Child" },
          "1" => { name: "Child Two", date_of_birth: "2015-08-02", relationship: "Child" }
        }
      }
    }

    assert_redirected_to root_path
    profile = @member.reload.member_profile
    assert_equal "Father Name", profile.father_name
    assert_equal "Mother Name", profile.mother_name
    assert_equal "family", profile.family_status
    assert_equal "Spouse Name", profile.spouse_name
    assert_equal "Spouse Name", profile.spouse_family_member.name
    assert_equal "#{profile.membership_number}-S01", profile.spouse_family_member.membership_number
    assert_equal [ "Child One", "Child Two" ], profile.child_family_members.order(:name).pluck(:name)
    assert_equal [ Date.new(2010, 5, 1), Date.new(2015, 8, 2) ], profile.child_family_members.order(:name).pluck(:date_of_birth)
    assert profile.child_family_members.all? { |child| child.membership_number.start_with?("#{profile.membership_number}-C") }
  end

  test "profile update ignores stale family member ids" do
    other_user = User.create!(name: "Other Member", email: "other-family@example.test", password: "password123")
    other_profile = other_user.create_member_profile!(
      full_name: "Other Member",
      mobile_number: "08013572468",
      date_of_birth: Date.new(1990, 1, 1),
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo",
      family_status: :family
    )
    stale_child = other_profile.family_members.create!(name: "Other Child", relationship: "Child")

    @member.create_member_profile!(
      full_name: "Complete Member",
      mobile_number: "09024681357",
      date_of_birth: Date.new(1990, 1, 1),
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo",
      family_status: :family
    )
    sign_in @member

    patch profile_path, params: {
      member_profile: {
        full_name: "Complete Member",
        mobile_number: "09024681357",
        date_of_birth: "1990-01-01",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo",
        family_status: "family",
        spouse_name: "Spouse Name",
        family_members_attributes: {
          "0" => { id: stale_child.id, name: "My Child", relationship: "Child", _destroy: "0" }
        }
      }
    }

    assert_redirected_to profile_path
    assert_equal [ "My Child" ], @member.member_profile.reload.child_family_members.pluck(:name)
    assert_equal [ "Other Child" ], other_profile.child_family_members.reload.pluck(:name)
  end

  test "member profile shows address but hides map and admin contact actions" do
    @member.create_member_profile!(
      full_name: "Complete Member",
      mobile_number: "09024681357",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
    sign_in @member

    get profile_path

    assert_response :success
    assert_includes response.body, "Okubo"
    assert_not_includes response.body, "Google Map"
    assert_not_includes response.body, "google.com/maps"
    assert_no_match(/>Call</, response.body)
    assert_no_match(/>WhatsApp</, response.body)
  end
end
