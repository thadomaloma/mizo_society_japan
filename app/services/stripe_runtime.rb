module StripeRuntime
  class MissingGemError < StandardError; end

  def self.load!
    require "stripe"
    true
  rescue LoadError
    false
  end

  def self.available?
    defined?(::Stripe).present? || load!
  end

  def self.ensure_available!
    return if available?

    raise MissingGemError, "Online payment dependency is not installed. Run `bundle install`, then restart the Rails server."
  end

  def self.configure!
    return unless available?

    ::Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key).presence || ENV["STRIPE_SECRET_KEY"]
  end
end
