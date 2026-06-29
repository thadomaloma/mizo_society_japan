module Webhooks
  class StripeController < ActionController::API
    def create
      StripePaymentSyncer.call(event: stripe_event)
      head :ok
    rescue JSON::ParserError, StripeRuntime::MissingGemError
      head :bad_request
    rescue StandardError => error
      raise unless stripe_signature_error?(error)

      head :bad_request
    end

    private

    def stripe_event
      payload = request.body.read
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret).presence || ENV["STRIPE_WEBHOOK_SECRET"]
      StripeRuntime.ensure_available!
      return ::Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true)) if endpoint_secret.blank?

      ::Stripe::Webhook.construct_event(payload, request.headers["Stripe-Signature"], endpoint_secret)
    end

    def stripe_signature_error?(error)
      defined?(::Stripe::SignatureVerificationError) && error.is_a?(::Stripe::SignatureVerificationError)
    end
  end
end
