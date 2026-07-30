require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:member)
    ensure_profile_for(@admin)
    ensure_profile_for(@member, mobile_number: "08013572468")
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

  test "event and announcement search results link to their detail pages" do
    event = Event.create!(
      title: "Searchable Community Gathering",
      event_category: event_categories(:general),
      created_by: @admin,
      event_date: Date.tomorrow,
      start_time_of_day: "10:00",
      venue: "Tokyo",
      description: "Searchable event details.",
      status: :published,
      visibility: :members_only,
      published_at: Time.current
    )
    announcement = Announcement.create!(
      title: "Searchable Community Notice",
      body: "Searchable announcement details.",
      category: :general,
      status: :published,
      published_at: Time.current,
      author: @admin
    )
    sign_in @member

    get global_search_path(q: "Searchable Community"), headers: { "Turbo-Frame" => "global_search_results" }

    assert_response :success
    assert_select "a[href='#{event_path(event)}']"
    assert_select "a[href='#{announcement_path(announcement)}']"
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
