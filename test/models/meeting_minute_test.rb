require "test_helper"

class MeetingMinuteTest < ActiveSupport::TestCase
  test "agenda numbering without agenda text is invalid" do
    minute = signature_test_minute
    minute.summary = "<div>1)&nbsp;</div>"

    assert_not minute.valid?
    assert_includes minute.errors[:summary], "must include meeting agenda text"
  end

  test "signature uploads must be PNG files" do
    minute = signature_test_minute
    minute.chairman_signature.attach(
      io: StringIO.new("fake jpeg"),
      filename: "signature.jpg",
      content_type: "image/jpeg"
    )

    assert_not minute.valid?
    assert_includes minute.errors[:chairman_signature], "must be a PNG image"
  end

  test "clear PNG signature uploads are accepted" do
    minute = signature_test_minute
    signature_file = Rails.root.join("public/icons/msj-portal-512x512-20260713.png")
    minute.chairman_signature.attach(
      io: File.open(signature_file),
      filename: "signature.png",
      content_type: "image/png"
    )

    assert minute.valid?
  end

  private

  def signature_test_minute
    MeetingMinute.new(
      title: "Signature Validation Test",
      meeting_date: Date.current,
      meeting_time: "10:00",
      summary: "Agenda item",
      uploaded_by: users(:admin)
    )
  end
end
