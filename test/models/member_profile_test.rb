require "test_helper"

class MemberProfileTest < ActiveSupport::TestCase
  test "accepts and normalizes domestic Japan mobile numbers" do
    profile = build_profile(mobile_number: "090-2468-1357")

    assert profile.valid?
    assert_equal "09024681357", profile.mobile_number
  end

  test "accepts and normalizes plus eighty one Japan mobile numbers" do
    profile = build_profile(mobile_number: "+81 90-2468-1357")

    assert profile.valid?
    assert_equal "09024681357", profile.mobile_number
  end

  test "rejects non Japan mobile numbers" do
    profile = build_profile(mobile_number: "+91 98765 43210")

    assert_not profile.valid?
    assert_includes profile.errors[:mobile_number], "must be a valid Japan mobile number starting with 070, 080, or 090"
  end

  test "requires address line one to include a street number" do
    profile = build_profile(mobile_number: "09024681357")
    profile.address_line1 = "南大野"

    assert_not profile.valid?
    assert_includes profile.errors[:address_line1], "must include a street or building number"
  end

  test "accepts address line one with full width street number" do
    profile = build_profile(mobile_number: "09024681357")
    profile.address_line1 = "南大野３-１１-２"

    assert profile.valid?
  end

  test "rejects example mobile numbers" do
    profile = build_profile(mobile_number: "07012345678")

    assert_not profile.valid?
    assert_includes profile.errors[:mobile_number], "cannot be an example or placeholder number"
  end

  test "rejects repeated placeholder mobile numbers" do
    profile = build_profile(mobile_number: "09000000000")

    assert_not profile.valid?
    assert_includes profile.errors[:mobile_number], "cannot be an example or placeholder number"
  end

  test "family profile keeps spouse as a synchronized beneficiary" do
    profile = build_profile(mobile_number: "09024681357")
    profile.family_status = :family
    profile.spouse_name = "Original Spouse"
    profile.save!

    spouse = profile.spouse_family_member
    assert_equal "Original Spouse", spouse.name
    assert_equal "#{profile.membership_number}-S01", spouse.membership_number

    profile.update!(spouse_name: "Updated Spouse")

    assert_equal spouse.id, profile.reload.spouse_family_member.id
    assert_equal "Updated Spouse", spouse.reload.name
  end

  private

  def build_profile(mobile_number:)
    users(:member).build_member_profile(
      full_name: "Member User",
      mobile_number: mobile_number,
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :single,
      postal_code: "169-0075",
      prefecture: "東京都",
      city: "新宿区",
      address_line1: "1-1-1"
    )
  end
end
