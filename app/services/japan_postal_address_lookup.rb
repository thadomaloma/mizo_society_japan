require "json"
require "net/http"

class JapanPostalAddressLookup
  ENDPOINT = URI("https://zipcloud.ibsnet.co.jp/api/search").freeze
  Address = Data.define(:prefecture, :city, :town)
  Result = Data.define(:status, :addresses) do
    def success?
      status == :success
    end

    def not_found?
      status == :not_found
    end
  end

  class << self
    def call(postal_code)
      normalized = MemberProfile.normalize_postal_code(postal_code)
      return Result.new(status: :not_found, addresses: []) unless normalized.match?(MemberProfile::JAPAN_POSTAL_CODE_REGEX)

      cache_key = "japan-postal-address/v1/#{normalized}"
      payload = Rails.cache.read(cache_key)
      unless payload
        payload = fetch(normalized)
        Rails.cache.write(cache_key, payload, expires_in: 7.days) unless payload["status"] == "unavailable"
      end
      build_result(payload)
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError
      Result.new(status: :unavailable, addresses: [])
    end

    private

    def fetch(postal_code)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(zipcode: postal_code.delete("-"))
      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true,
        open_timeout: 3,
        read_timeout: 4
      ) { |http| http.request(request) }

      return { "status" => "unavailable", "results" => [] } unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def build_result(payload)
      return Result.new(status: :unavailable, addresses: []) if payload["status"] == "unavailable"

      addresses = Array(payload["results"]).filter_map do |entry|
        prefecture = JapanPrefecture.canonical(entry["address1"])
        next if prefecture.blank? || entry["address2"].blank?

        Address.new(prefecture: prefecture, city: entry["address2"].to_s.strip, town: entry["address3"].to_s.strip)
      end
      Result.new(status: addresses.any? ? :success : :not_found, addresses: addresses)
    end
  end
end
