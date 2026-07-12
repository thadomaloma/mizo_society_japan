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

  test "signature image width stays close to the displayed name" do
    builder = MeetingMinutePdfBuilder.allocate

    short_name_width = builder.send(:signature_image_width_for, "Secretary")
    long_name_width = builder.send(:signature_image_width_for, "Dr. Lalramzaua Chhangte")

    assert_equal MeetingMinutePdfBuilder::SIGNATURE_MIN_WIDTH, short_name_width
    assert_operator long_name_width, :>, short_name_width
    assert_operator long_name_width, :<=, MeetingMinutePdfBuilder::SIGNATURE_MAX_WIDTH
  end

  test "signature name is positioned close below the image" do
    builder = MeetingMinutePdfBuilder.allocate
    builder.instance_variable_set(:@current_content, +"")
    builder.instance_variable_set(:@cursor_y, 200.0)
    builder.define_singleton_method(:draw_signature_image) { |*, **| true }

    builder.send(:signature_block, 160.0, "Chairman Name", "President", attachment: nil)
    content = builder.instance_variable_get(:@current_content)

    assert_includes content, "176.00 Td (CHAIRMAN NAME)"
    assert_includes content, "160.00 Td (President)"
    assert_includes content, "144.00 Td (Mizo Society of Japan)"
  end
end
