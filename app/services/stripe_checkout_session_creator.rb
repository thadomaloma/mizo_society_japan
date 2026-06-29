class StripeCheckoutSessionCreator
  def self.call(membership_payment:, request:)
    new(membership_payment:, request:).call
  end

  def initialize(membership_payment:, request:)
    @membership_payment = membership_payment
    @request = request
  end

  def call
    StripeRuntime.ensure_available!
    StripeRuntime.configure!
    ensure_stripe_configured!
    ensure_checkoutable!

    session = ::Stripe::Checkout::Session.create(session_params)
    membership_payment.update!(
      payment_method: :online_card,
      status: :pending,
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      stripe_customer_id: session.customer,
      stripe_status: session.status,
      checkout_expires_at: session.expires_at ? Time.zone.at(session.expires_at) : nil
    )
    session
  rescue StripeRuntime::MissingGemError => error
    raise StripeConfigurationError, error.message
  rescue StandardError => error
    raise StripeCheckoutError, error.message if stripe_error?(error)

    raise
  end

  private

  attr_reader :membership_payment, :request

  def ensure_stripe_configured!
    raise StripeConfigurationError, "Online payment is not configured yet." if ::Stripe.api_key.blank?
  end

  def ensure_checkoutable!
    return if membership_payment.online_checkoutable?

    raise StripeCheckoutError, "This payment cannot be paid online."
  end

  def session_params
    {
      mode: "payment",
      customer: stripe_customer_id,
      payment_method_types: [ "card" ],
      line_items: [ line_item ],
      metadata: metadata,
      payment_intent_data: { metadata: metadata },
      success_url: success_membership_payment_url(membership_payment, session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: cancel_membership_payment_url(membership_payment, session_id: "{CHECKOUT_SESSION_ID}")
    }
  end

  def stripe_customer_id
    return membership_payment.stripe_customer_id if membership_payment.stripe_customer_id.present?

    customer = ::Stripe::Customer.create(
      email: membership_payment.user.email,
      name: membership_payment.user.display_name,
      metadata: { user_id: membership_payment.user_id }
    )
    membership_payment.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def line_item
    {
      quantity: 1,
      price_data: {
        currency: "jpy",
        unit_amount: membership_payment.amount.to_i,
        product_data: {
          name: membership_payment.membership_plan.name,
          description: "#{membership_payment.plan_type_label} payment #{membership_payment.period_label}"
        }
      }
    }
  end

  def metadata
    {
      membership_payment_id: membership_payment.id,
      user_id: membership_payment.user_id,
      membership_plan_id: membership_payment.membership_plan_id
    }
  end

  def success_membership_payment_url(payment, session_id:)
    Rails.application.routes.url_helpers.success_membership_payment_url(
      payment,
      session_id: session_id,
      host: request.base_url
    )
  end

  def cancel_membership_payment_url(payment, session_id:)
    Rails.application.routes.url_helpers.cancel_membership_payment_url(
      payment,
      session_id: session_id,
      host: request.base_url
    )
  end

  def stripe_error?(error)
    defined?(::Stripe::StripeError) && error.is_a?(::Stripe::StripeError)
  end

  class StripeCheckoutError < StandardError; end
  class StripeConfigurationError < StandardError; end
end
