require "test_helper"

class MeetingMinutePdfBuilderTest < ActiveSupport::TestCase
  test "PNG sub filters use reconstructed pixels" do
    builder = MeetingMinutePdfBuilder.allocate

    decoded = builder.send(
      :png_unfilter,
      [ 10, 20, 30, 40, 1, 2, 3, 4, 1, 2, 3, 4 ],
      Array.new(12, 0),
      4,
      1
    )

    assert_equal [ 10, 20, 30, 40, 11, 22, 33, 44, 12, 24, 36, 48 ], decoded
  end

  test "decision numbering and headings stay bold while body and sub-items stay regular" do
    builder = MeetingMinutePdfBuilder.allocate
    lines = builder.send(
      :decision_rich_lines,
      "<div><strong>1. Chapchar kut chungchang:</strong> Decision body</div><div>1) Pastor Tawnluia</div>"
    )

    assert_equal [
      [
        { text: "1. Chapchar kut chungchang:", bold: true },
        { text: " Decision body", bold: false }
      ],
      [ { text: "1) Pastor Tawnluia", bold: false } ]
    ], lines
  end
end
