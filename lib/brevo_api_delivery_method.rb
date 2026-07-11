require "base64"
require "json"
require "net/http"

class BrevoApiDeliveryMethod
  ENDPOINT = URI("https://api.brevo.com/v3/smtp/email")

  class DeliveryError < StandardError; end

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    request = Net::HTTP::Post.new(ENDPOINT)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["api-key"] = @settings.fetch(:api_key)
    request.body = payload_for(mail).to_json

    http = http_client
    http.use_ssl = true
    http.open_timeout = @settings.fetch(:open_timeout, 5)
    http.read_timeout = @settings.fetch(:read_timeout, 15)
    response = http.request(request)

    return response if response.code.to_i.between?(200, 299)

    raise DeliveryError, "Brevo API delivery failed (HTTP #{response.code}): #{response_message(response)}"
  end

  private

  def http_client
    return @settings[:http_factory].call if @settings[:http_factory].respond_to?(:call)

    Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
  end

  def payload_for(mail)
    payload = {
      sender: {
        email: mail.from&.first || @settings.fetch(:sender_email),
        name: @settings.fetch(:sender_name, "Mizo Society of Japan")
      },
      to: recipients(mail.to),
      cc: recipients(mail.cc),
      bcc: recipients(mail.bcc),
      replyTo: reply_to(mail),
      subject: mail.subject.to_s,
      htmlContent: html_content(mail),
      textContent: text_content(mail),
      attachment: attachments(mail)
    }

    payload.compact.reject { |_key, value| value.respond_to?(:empty?) && value.empty? }
  end

  def recipients(addresses)
    Array(addresses).filter_map { |email| { email: email.to_s }.presence }
  end

  def reply_to(mail)
    email = mail.reply_to&.first
    { email: email } if email.present?
  end

  def html_content(mail)
    return mail.html_part.decoded if mail.html_part.present?
    return mail.body.decoded if mail.mime_type == "text/html"
  end

  def text_content(mail)
    return mail.text_part.decoded if mail.text_part.present?
    return if mail.html_part.present? || mail.mime_type == "text/html"

    mail.body.decoded
  end

  def attachments(mail)
    mail.attachments.map do |attachment|
      {
        name: attachment.filename,
        content: Base64.strict_encode64(attachment.body.decoded)
      }
    end
  end

  def response_message(response)
    body = JSON.parse(response.body.to_s)
    body["message"].presence || body["code"].presence || "Unknown Brevo error"
  rescue JSON::ParserError
    response.body.to_s.truncate(300).presence || "Unknown Brevo error"
  end
end
