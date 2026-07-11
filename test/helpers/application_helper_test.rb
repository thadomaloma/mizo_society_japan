require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "image variant falls back to original when the processor is unavailable" do
    image = Object.new
    @image_variant_processor_available = false

    assert_same image, image_variant_or_original(image, resize_to_fill: [ 96, 96 ])
  end
end
