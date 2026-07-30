require "test_helper"

class NotificationCreatorTest < ActiveSupport::TestCase
  test "office bearer event notifications do not reach regular members" do
    event = create_event!(visibility: :office_bearers_only)

    NotificationCreator.event_created(event, actor: users(:admin))

    assert Notification.exists?(recipient: users(:admin), notifiable: event, action: :event_created)
    assert_not Notification.exists?(recipient: users(:member), notifiable: event, action: :event_created)
  end

  test "event notifications are removed when published visibility becomes restricted" do
    event = create_event!(visibility: :members_only)
    NotificationCreator.event_created(event, actor: users(:admin))
    assert Notification.exists?(recipient: users(:member), notifiable: event, action: :event_created)

    event.update!(visibility: :office_bearers_only)
    NotificationCreator.event_created(event, actor: users(:admin))

    assert_not Notification.exists?(recipient: users(:member), notifiable: event, action: :event_created)
  end

  test "inactive users do not receive portal-wide notifications" do
    users(:member).update!(active: false)
    announcement = Announcement.create!(
      title: "Member update",
      body: "A portal update.",
      category: :general,
      status: :published,
      published_at: Time.current,
      author: users(:admin)
    )

    NotificationCreator.announcement_published(announcement, actor: users(:admin))

    assert_not Notification.exists?(recipient: users(:member), notifiable: announcement)
  end

  test "stale notification for archived content is excluded from the member feed" do
    announcement = Announcement.create!(
      title: "Temporary member update",
      body: "This update was later archived.",
      category: :general,
      status: :published,
      published_at: Time.current,
      author: users(:admin)
    )
    NotificationCreator.announcement_published(announcement, actor: users(:admin))
    notification = Notification.find_by!(recipient: users(:member), notifiable: announcement)
    announcement.update_column(:status, Announcement.statuses.fetch("archived"))

    assert_not_includes Notification.relevant_to(users(:member)), notification
  end

  private

  def create_event!(visibility:)
    Event.create!(
      title: "Committee gathering",
      event_category: event_categories(:general),
      created_by: users(:admin),
      event_date: Date.tomorrow,
      start_time_of_day: "10:00",
      venue: "Shinjuku, Tokyo",
      description: "A scheduled MSJ event.",
      status: :published,
      visibility: visibility,
      published_at: Time.current
    )
  end
end
