require "test_helper"

class BrevoApiDeliveryMethodTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body)

  class FakeHttp
    attr_accessor :use_ssl, :open_timeout, :read_timeout
    attr_reader :last_request

    def initialize(response)
      @response = response
    end

    def request(request)
      @last_request = request
      @response
    end
  end

  test "delivers a text email through the Brevo HTTPS API" do
    http = FakeHttp.new(FakeResponse.new("201", '{"messageId":"test-id"}'))
    delivery = delivery_method(http)
    mail = Mail.new(
      from: "mizosocietyjapan@gmail.com",
      to: "member@example.test",
      subject: "MSJ test",
      body: "Email body"
    )

    response = delivery.deliver!(mail)
    payload = JSON.parse(http.last_request.body)

    assert_equal "201", response.code
    assert_equal "secret-api-key", http.last_request["api-key"]
    assert_equal "mizosocietyjapan@gmail.com", payload.dig("sender", "email")
    assert_equal [ { "email" => "member@example.test" } ], payload["to"]
    assert_equal "MSJ test", payload["subject"]
    assert_equal "Email body", payload["textContent"]
    assert http.use_ssl
  end

  test "exposes delivery settings for Action Mailer compatibility" do
    delivery = delivery_method(FakeHttp.new(FakeResponse.new("201", "{}")))

    assert_equal "secret-api-key", delivery.settings[:api_key]
    assert_equal "mizosocietyjapan@gmail.com", delivery.settings[:sender_email]
  end

  test "raises a useful error without exposing the API key" do
    http = FakeHttp.new(FakeResponse.new("401", '{"message":"Key not found"}'))

    error = assert_raises(BrevoApiDeliveryMethod::DeliveryError) do
      delivery_method(http).deliver!(Mail.new(to: "member@example.test", subject: "Test", body: "Body"))
    end

    assert_includes error.message, "HTTP 401"
    assert_includes error.message, "Key not found"
    assert_not_includes error.message, "secret-api-key"
  end

  private

  def delivery_method(http)
    BrevoApiDeliveryMethod.new(
      api_key: "secret-api-key",
      sender_email: "mizosocietyjapan@gmail.com",
      sender_name: "Mizo Society of Japan",
      http_factory: -> { http }
    )
  end
end
