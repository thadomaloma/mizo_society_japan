require "test_helper"

class JapanPrefectureTest < ActiveSupport::TestCase
  test "returns one romaji name for kanji and existing romaji values" do
    assert_equal "Tokyo", JapanPrefecture.romaji("東京都")
    assert_equal "Tokyo", JapanPrefecture.romaji("Tokyo")
  end

  test "preserves an unknown nonblank value and handles blanks" do
    assert_equal "Overseas", JapanPrefecture.romaji(" Overseas ")
    assert_nil JapanPrefecture.romaji(nil)
    assert_nil JapanPrefecture.romaji(" ")
  end
end
