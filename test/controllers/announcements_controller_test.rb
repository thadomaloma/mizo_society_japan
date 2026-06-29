require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    @assistant_secretary = create_user("Assistant Secretary", "assistant_announcements@example.test", :assistant_secretary, "08012345678")
    @journal_secretary = create_user("Journal Secretary", "journal_announcements@example.test", :journal_secretary, "08012345679")
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "07012345678")
  end

  test "members see published announcements and opening one records a read" do
    published = create_announcement(title: "Published MSJ Notice", status: :published)
    draft = create_announcement(title: "Private Draft Notice", status: :draft)
    sign_in @member

    get announcements_path

    assert_response :success
    assert_includes response.body, published.title
    assert_not_includes response.body, draft.title

    assert_difference -> { AnnouncementRead.count }, 1 do
      get announcement_path(published)
    end

    assert_response :success
    assert published.read_by?(@member)

    get announcement_path(draft)
    assert_response :not_found
  end

  test "assistant secretary can create and publish an announcement" do
    sign_in @assistant_secretary

    assert_difference -> { Announcement.count }, 1 do
      post announcements_path, params: {
        announcement: {
          title: "Sports Day Registration",
          body: "Registration is now open for the MSJ Sports Day.",
          category: :event,
          pinned: "1"
        }
      }
    end

    announcement = Announcement.last
    assert_redirected_to announcement_path(announcement)
    assert announcement.draft?
    assert announcement.pinned?

    patch publish_announcement_path(announcement)

    assert_redirected_to announcement_path(announcement)
    assert announcement.reload.published?
    assert announcement.published_at.present?
  end

  test "journal secretary cannot create announcements" do
    sign_in @journal_secretary

    assert_no_difference -> { Announcement.count } do
      post announcements_path, params: {
        announcement: {
          title: "Journal Draft Notice",
          body: "This should not be created.",
          category: :event
        }
      }
    end

    assert_redirected_to root_path
  end

  private

  def create_announcement(title:, status:)
    Announcement.create!(
      title: title,
      body: "Important information for Mizo Society of Japan members.",
      category: :general,
      status: status,
      published_at: status == :published ? Time.current : nil,
      author: @president
    )
  end

  def create_user(name, email, role, mobile_number)
    user = User.create!(name: name, email: email, password: "password123", role: role)
    ensure_profile_for(user, mobile_number: mobile_number)
    user
  end

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
