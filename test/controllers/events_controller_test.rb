require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    @assistant_secretary = create_user("Assistant Secretary", "assistant_events@example.test", :assistant_secretary, "08013572468")
    @journal_secretary = create_user("Journal Secretary", "journal_events@example.test", :journal_secretary, "08012345679")
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "07024681359")
  end

  test "assistant secretary can create an event draft" do
    sign_in @assistant_secretary

    assert_difference -> { Event.count }, 1 do
      post events_path, params: { event: event_params(title: "MSJ Summer Sports Day") }
    end

    event = Event.last
    assert_redirected_to event_path(event)
    assert event.draft?
    assert_equal "MSJ Summer Sports Day", event.title
    assert_equal "10:30", event.start_time.strftime("%H:%M")
    assert_equal "Shinjuku Sports Centre", event.venue
  end

  test "journal secretary cannot create event drafts" do
    sign_in @journal_secretary

    assert_no_difference -> { Event.count } do
      post events_path, params: { event: event_params(title: "Journal Draft Event") }
    end

    assert_redirected_to root_path
  end

  test "members can only see published events" do
    published_event = create_event(title: "Published Community Day", status: :published)
    draft_event = create_event(title: "Private Draft Day", status: :draft)
    sign_in @member

    get events_path

    assert_response :success
    assert_includes response.body, published_event.title
    assert_not_includes response.body, draft_event.title

    get event_path(draft_event)
    assert_response :not_found
  end

  test "member can RSVP to an open published event" do
    event = create_event(title: "Member RSVP Event", status: :published, registration_required: true, max_participants: 25)
    sign_in @member

    assert_difference -> { EventRegistration.count }, 1 do
      post rsvp_event_path(event)
    end

    assert_redirected_to event_path(event)
    assert event.event_registrations.find_by!(user: @member).going?
  end

  test "member can RSVP when an event has no participant limit" do
    event = create_event(title: "Open Community Event", status: :published, registration_required: true)
    sign_in @member

    assert_difference -> { EventRegistration.count }, 1 do
      post rsvp_event_path(event)
    end

    assert_redirected_to event_path(event)
  end

  test "member can withdraw an existing RSVP" do
    event = create_event(title: "RSVP Withdrawal Event", status: :published, registration_required: true)
    registration = EventRegistration.create!(event: event, user: @member, status: :going)
    sign_in @member

    patch withdraw_rsvp_event_path(event)

    assert_redirected_to event_path(event)
    assert registration.reload.cancelled?
  end

  test "event details provide a calendar download and managers can view RSVPs" do
    event = create_event(title: "Calendar Event", status: :published, registration_required: true)
    EventRegistration.create!(event: event, user: @member, status: :going, note: "Bringing a guest")

    sign_in @assistant_secretary
    get event_path(event)

    assert_response :success
    assert_includes response.body, "RSVPs"
    assert_includes response.body, @member.name

    get calendar_event_path(event, format: :ics)

    assert_response :success
    assert_includes response.media_type, "text/calendar"
    assert_includes response.body, "BEGIN:VCALENDAR"
    assert_includes response.body, "SUMMARY:Calendar Event"
  end

  test "members cannot create events" do
    sign_in @member

    get new_event_path

    assert_redirected_to root_path
  end

  private

  def event_params(title:)
    {
      title: title,
      event_date: Date.tomorrow,
      start_time_of_day: "10:30",
      venue: "Shinjuku Sports Centre",
      description: "A community event for Mizo Society of Japan members.",
      registration_required: "1",
      max_participants: "25"
    }
  end

  def create_event(title:, status:, registration_required: false, max_participants: nil)
    event = Event.new(event_params(title: title).merge(registration_required: registration_required, max_participants: max_participants))
    event.created_by = @president
    event.status = status
    event.published_at = Time.current if status == :published
    event.save!
    event
  end

  def create_user(name, email, role, mobile_number)
    user = User.create!(name: name, email: email, password: "password123", role: role)
    ensure_profile_for(user, mobile_number: mobile_number)
    user
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
