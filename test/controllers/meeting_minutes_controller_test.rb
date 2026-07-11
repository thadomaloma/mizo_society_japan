require "test_helper"

class MeetingMinutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    @executive = create_user("Executive Member", "executive_minutes@example.test", :executive_member, "07024681359")
    @finance_secretary = create_user("Finance Secretary", "finance_minutes@example.test", :finance_secretary, "08012345679")
    @assistant_secretary = create_user("Assistant Secretary", "welfare_minutes@example.test", :assistant_secretary, "09012345679")
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08013572468")
  end

  test "president can save a simple draft with attendees and decisions" do
    sign_in @president

    assert_difference -> { MeetingMinute.count }, 1 do
      post meeting_minutes_path, params: {
        meeting_minute: {
          title: "Executive Committee Meeting",
          meeting_date: Date.current,
          meeting_time: "10:00",
          venue: "Shinjuku, Tokyo",
          chairman: "Lalrammawia",
          minute_recorder: "Vanlalhruaia",
          opening_prayer: "Lalbiakzuali",
          welcome_speech: "Welcome remarks by the Chairman.",
          previous_minutes_approval: "Previous minutes were read and approved.",
          reports: "Treasurer's report was received.",
          summary: "The committee reviewed the portal update.",
          decisions: "1. Publish the new minutes format.",
          adjournment: "The meeting was closed with prayer.",
          present_attendee_ids: [ @president.id ],
          apology_attendee_ids: [ @assistant_secretary.id ]
        }
      }
    end

    minute = MeetingMinute.last
    assert_redirected_to meeting_minute_path(minute)
    assert minute.draft?
    assert_equal [ @president.id ], minute.attendance_ids_for(:present)
    assert_equal [ @assistant_secretary.id ], minute.attendance_ids_for(:apology)
    assert_empty minute.attendance_ids_for(:absent)
    assert_not_includes minute.meeting_minute_attendances.map(&:user_id), @finance_secretary.id
    assert_not_includes minute.meeting_minute_attendances.map(&:user_id), @executive.id
    assert_equal "1. Publish the new minutes format.", minute.decisions
    assert_equal 2, minute.attendance_total
    assert_equal "Lalrammawia", minute.chairman
    assert_equal "Welcome remarks by the Chairman.", minute.welcome_speech
    assert_equal "Previous minutes were read and approved.", minute.previous_minutes_approval
    assert_equal "Treasurer's report was received.", minute.reports
    assert_equal "The meeting was closed with prayer.", minute.adjournment
  end

  test "president can save and publish a minute from the form" do
    sign_in @president

    assert_difference -> { MeetingMinute.published.count }, 1 do
      post meeting_minutes_path, params: {
        commit_action: "publish",
        meeting_minute: valid_minute_params(title: "Ready Meeting Minute")
      }
    end

    minute = MeetingMinute.last
    assert_redirected_to meeting_minute_path(minute)
    assert minute.published?
    assert_not_nil minute.published_at
  end

  test "formatted meeting agenda is saved when the rich text editor submits its hidden field" do
    sign_in @president

    post meeting_minutes_path, params: {
      meeting_minute: valid_minute_params(title: "Formatted Agenda").merge(
        summary: "<div><strong>1. Opening prayer</strong></div><div>2. Finance update</div>"
      )
    }

    minute = MeetingMinute.last
    assert_redirected_to meeting_minute_path(minute)
    assert_includes minute.summary, "Opening prayer"
    assert_includes minute.summary, "<strong>"
  end

  test "minutes form has only the simple meeting fields" do
    sign_in @president

    get new_meeting_minute_path

    assert_response :success
    assert_includes response.body, "Meeting Time"
    assert_not_includes response.body, "Meeting Type"
    assert_not_includes response.body, "Visibility"
    assert_not_includes response.body, "Chairman</label>"
    assert_not_includes response.body, "Minute Recorder</label>"
    assert_includes response.body, "Opening Prayer"
    assert_includes response.body, "Welcome Speech"
    assert_includes response.body, "Previous Minute Approval"
    assert_includes response.body, "Reports"
    assert_includes response.body, "Meeting Agenda"
    assert_not_includes response.body, "Add item"
    assert_includes response.body, "Click to add the first agenda item"
    assert_includes response.body, "Decisions / Resolutions"
    assert_includes response.body, "Adjournment"
    assert_includes response.body, "Mark members who attended, then record apologies separately."
    assert_includes response.body, "Apologies"
    assert_not_includes response.body, "Marked absent."
    assert_includes response.body, "Underline"
    assert_not_includes response.body, "Bullet list"
    assert_includes response.body, "Signature block"
    assert_includes response.body, "Chairman Signature PNG"
    assert_includes response.body, "Secretary Signature PNG"
    assert_includes response.body, "PNG only"
    assert_includes response.body, "Save Draft"
    assert_includes response.body, "Publish"
    assert_not_includes response.body, "PDF Attachment"
    assert_not_includes response.body, "Resolution tracking"
    assert_not_includes response.body, "Write meeting minutes"
  end

  test "president can view and edit a meeting record from the minutes list" do
    minute = create_minute(status: :draft)
    sign_in @president

    get meeting_minutes_path
    assert_response :success
    assert_includes response.body, meeting_minute_path(minute)
    assert_includes response.body, edit_meeting_minute_path(minute)

    get edit_meeting_minute_path(minute)
    assert_response :success

    patch meeting_minute_path(minute), params: { meeting_minute: valid_minute_params(title: "Updated Executive Meeting") }
    assert_redirected_to meeting_minute_path(minute)
    assert_equal "Updated Executive Meeting", minute.reload.title
  end

  test "published minute edit form shows update action instead of draft publish actions" do
    minute = create_minute(status: :published)
    sign_in @president

    get edit_meeting_minute_path(minute)

    assert_response :success
    assert_includes response.body, "Update Minute"
    assert_not_includes response.body, "Save Draft"
  end

  test "authorised minutes viewers can export the record as an A4 PDF" do
    minute = create_minute(status: :published)
    signature_file = Rails.root.join("public/icons/msj-portal-512x512-20260709.png")
    minute.chairman_signature.attach(
      io: File.open(signature_file),
      filename: "chairman-signature.png",
      content_type: "image/png"
    )
    minute.secretary_signature.attach(
      io: File.open(signature_file),
      filename: "secretary-signature.png",
      content_type: "image/png"
    )
    sign_in @executive

    get export_pdf_meeting_minute_path(minute)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.body, "%PDF-1.4"
    assert_includes response.body, "/Subtype /Image"
    assert_includes response.body, "/XObject"
    assert_includes response.body, "/Interpolate false"
  end

  test "members cannot access meeting minutes" do
    published_minute = create_minute(status: :published)

    sign_in @member
    get meeting_minutes_path
    assert_response :success
    assert_not_includes response.body, published_minute.title

    get meeting_minute_path(published_minute)
    assert_response :not_found
  end

  test "executive members can view published minutes" do
    minute = create_minute(status: :published)

    sign_in @executive
    get meeting_minute_path(minute)

    assert_response :success
  end

  test "finance and welfare teams can view published minutes" do
    finance_minute = create_minute(status: :published)
    welfare_minute = create_minute(status: :published)

    sign_in @finance_secretary
    get meeting_minute_path(finance_minute)
    assert_response :success

    sign_in @assistant_secretary
    get meeting_minute_path(welfare_minute)
    assert_response :success
  end

  test "published minutes notify authorised minutes viewers, not ordinary members" do
    minute = create_minute(status: :draft)
    sign_in @president

    patch publish_meeting_minute_path(minute)

    assert_redirected_to meeting_minute_path(minute)
    assert minute.reload.published?
    assert Notification.exists?(recipient: @executive, notifiable: minute, action: :meeting_minute_published)
    assert_not Notification.exists?(recipient: @member, notifiable: minute, action: :meeting_minute_published)
  end

  private

  def create_minute(status:)
    MeetingMinute.create!(
      title: "#{status.to_s.humanize} Meeting Minutes #{SecureRandom.hex(3)}",
      meeting_date: Date.current,
      meeting_time: "10:00",
      summary: "Published meeting summary.",
      status: status,
      uploaded_by: @president
    )
  end

  def valid_minute_params(title:)
    {
      title: title,
      meeting_date: Date.current,
      meeting_time: "10:00",
      venue: "Shinjuku, Tokyo",
      chairman: "Lalrammawia",
      minute_recorder: "Vanlalhruaia",
      opening_prayer: "Lalbiakzuali",
      welcome_speech: "Welcome remarks by the Chairman.",
      previous_minutes_approval: "Previous minutes were read and approved.",
      reports: "Treasurer's report was received.",
      summary: "Updated meeting agenda.",
      decisions: "1. Record the update.",
      adjournment: "The meeting was closed with prayer.",
      present_attendee_ids: [ @president.id ]
    }
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
        date_of_birth: Date.new(1990, 1, 1),
        family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end

end
