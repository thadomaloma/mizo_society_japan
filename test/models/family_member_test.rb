require "test_helper"

class FamilyMemberTest < ActiveSupport::TestCase
  setup do
    @profile = users(:member).member_profile || users(:member).create_member_profile!(
      full_name: "Family Test Member",
      mobile_number: "07024681357",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :family,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
    @profile.update!(family_status: :family)
  end

  test "generates child membership number under guardian membership number" do
    first_child = @profile.family_members.create!(name: "First Child", relationship: "Child")
    second_child = @profile.family_members.create!(name: "Second Child", relationship: "Child")

    assert_equal "#{@profile.membership_number}-C01", first_child.membership_number
    assert_equal "#{@profile.membership_number}-C02", second_child.membership_number
  end

  test "generates spouse membership number under account holder membership number" do
    spouse = @profile.family_members.create!(name: "Family Spouse", relationship: "Spouse")

    assert_equal "#{@profile.membership_number}-S01", spouse.membership_number
    assert spouse.spouse?
    assert_not spouse.child?
  end

  test "membership fee eligibility starts on fourteenth birthday" do
    today = Date.new(2026, 7, 13)
    child = @profile.family_members.build(
      name: "Eligible Child",
      relationship: "Child",
      date_of_birth: Date.new(2012, 7, 13)
    )

    assert_not child.membership_fee_eligible?(on: today.yesterday)
    assert child.membership_fee_eligible?(on: today)
  end
end
