require "test_helper"

class Admin::EventCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08012345678")
  end

  test "event manager can create and edit an event category" do
    sign_in @president

    assert_difference -> { EventCategory.count }, 1 do
      post admin_event_categories_path, params: { event_category: { name: "Community Service", position: 20, active: "1" } }
    end

    category = EventCategory.find_by!(name: "Community Service")
    assert_redirected_to admin_event_categories_path

    patch admin_event_category_path(category), params: { event_category: { name: "Community Outreach", position: 21, active: "0" } }

    assert_redirected_to admin_event_categories_path
    assert_equal "Community Outreach", category.reload.name
    assert_not category.active?
  end

  test "category used by events cannot be deleted" do
    category = EventCategory.create!(name: "Protected Event Category", active: true, position: 30)
    Event.create!(
      title: "Protected Category Event",
      event_category: category,
      event_date: Date.tomorrow,
      venue: "Tokyo",
      description: "An event that protects its category.",
      start_time: 1.day.from_now,
      end_time: 1.day.from_now + 2.hours,
      created_by: @president
    )
    sign_in @president

    assert_no_difference -> { EventCategory.count } do
      delete admin_event_category_path(category)
    end

    assert_redirected_to admin_event_categories_path
    assert_equal "This category is used by events and cannot be deleted.", flash[:alert]
  end

  test "members cannot manage event categories" do
    sign_in @member

    get admin_event_categories_path

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
