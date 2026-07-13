require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "action button classes come from the MSJ RubyUI button primitive" do
    classes = action_button_classes(:secondary, size: :xs, full_width: true, extra: "custom-class")

    assert_includes classes, "min-h-8"
    assert_includes classes, "border-[#CBD5E1]"
    assert_includes classes, "dark:bg-[#1E293B]"
    assert_includes classes, "w-full"
    assert_includes classes, "custom-class"
  end

  test "danger action button keeps the portal red treatment" do
    classes = action_button_classes(:danger)

    assert_includes classes, "bg-red-700"
    assert_includes classes, "focus:ring-red-600"
  end

  test "image variant falls back to original when the processor is unavailable" do
    image = Object.new
    @image_variant_processor_available = false

    assert_same image, image_variant_or_original(image, resize_to_fill: [ 96, 96 ])
  end
end
