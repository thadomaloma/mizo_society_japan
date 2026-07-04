require "test_helper"

class MeetingMinuteTest < ActiveSupport::TestCase
  test "signature uploads must be PNG files" do
    minute = MeetingMinute.new(
      title: "Signature Validation Test",
      meeting_date: Date.current,
      meeting_time: "10:00",
      summary: "Agenda item",
      uploaded_by: users(:admin)
    )
    minute.chairman_signature.attach(
      io: StringIO.new("fake jpeg"),
      filename: "signature.jpg",
      content_type: "image/jpeg"
    )

    assert_not minute.valid?
    assert_includes minute.errors[:chairman_signature], "must be a PNG image"
  end
end
