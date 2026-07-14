require "test_helper"

class JapanPostalAddressLookupTest < ActiveSupport::TestCase
  test "returns normalized Japan address results" do
    payload = {
      "results" => [
        { "address1" => "東京都", "address2" => "新宿区", "address3" => "百人町" }
      ]
    }
    Rails.cache.delete("japan-postal-address/v1/169-0075")

    result = with_stubbed_fetch(payload) do
      JapanPostalAddressLookup.call("1690075")
    end

    assert result.success?
    assert_equal "東京都", result.addresses.first.prefecture
    assert_equal "新宿区", result.addresses.first.city
    assert_equal "百人町", result.addresses.first.town
  end

  test "returns not found when postal code has no results" do
    Rails.cache.delete("japan-postal-address/v1/999-9999")

    result = with_stubbed_fetch({ "results" => nil }) do
      JapanPostalAddressLookup.call("999-9999")
    end

    assert result.not_found?
    assert_empty result.addresses
  end

  private

  def with_stubbed_fetch(payload)
    original = JapanPostalAddressLookup.method(:fetch)
    JapanPostalAddressLookup.define_singleton_method(:fetch) { |_postal_code| payload }
    yield
  ensure
    JapanPostalAddressLookup.define_singleton_method(:fetch, original)
    JapanPostalAddressLookup.singleton_class.send(:private, :fetch)
  end
end
