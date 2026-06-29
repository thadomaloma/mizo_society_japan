begin
  require "stripe"
  Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key).presence || ENV["STRIPE_SECRET_KEY"]
rescue LoadError
  Rails.logger.warn("Stripe gem is not available. Online payments will show a configuration error until `bundle install` and server restart are complete.")
end
