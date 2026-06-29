class StripePaymentSyncer
  HANDLED_EVENTS = %w[
    checkout.session.completed
    checkout.session.expired
    payment_intent.succeeded
    payment_intent.payment_failed
  ].freeze

  def self.call(event:)
    new(event:).call
  end

  def initialize(event:)
    @event = event
  end

  def call
    StripeRuntime.ensure_available!
    return unless HANDLED_EVENTS.include?(event.type)

    case event.type
    when "checkout.session.completed"
      sync_checkout_session(event.data.object)
    when "checkout.session.expired"
      mark_checkout_session_expired(event.data.object)
    when "payment_intent.succeeded"
      sync_payment_intent(event.data.object, paid: true)
    when "payment_intent.payment_failed"
      sync_payment_intent(event.data.object, paid: false)
    end
  end

  private

  attr_reader :event

  def sync_checkout_session(session)
    payment = find_payment_from_session(session)
    return if payment.blank?

    payment.update!(
      payment_method: :online_card,
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      stripe_customer_id: session.customer,
      stripe_status: session.status,
      checkout_expires_at: session.expires_at ? Time.zone.at(session.expires_at) : payment.checkout_expires_at
    )
    mark_paid!(payment, stripe_status: session.payment_status) if session.payment_status == "paid"
  end

  def mark_checkout_session_expired(session)
    payment = find_payment_from_session(session)
    return if payment.blank? || payment.paid?

    payment.update!(
      status: :expired,
      stripe_checkout_session_id: session.id,
      stripe_status: session.status,
      checkout_expires_at: session.expires_at ? Time.zone.at(session.expires_at) : payment.checkout_expires_at
    )
  end

  def sync_payment_intent(payment_intent, paid:)
    payment = find_payment_from_intent(payment_intent)
    return if payment.blank?

    payment.update!(
      payment_method: :online_card,
      stripe_payment_intent_id: payment_intent.id,
      stripe_customer_id: payment_intent.customer,
      stripe_status: payment_intent.status,
      stripe_payment_method_type: payment_method_type_from_payment_intent(payment_intent)
    )

    paid ? mark_paid!(payment, stripe_status: payment_intent.status) : payment.update!(status: :failed)
  end

  def mark_paid!(payment, stripe_status:)
    return if payment.paid?

    payment.update!(status: :paid, paid_on: Time.current, stripe_status: stripe_status)
    MembershipPaymentFinanceRecorder.call(payment: payment)
    NotificationCreator.payment_approved(payment, actor: payment.approved_by || payment.user)
    AuditLogger.call(
      user: nil,
      action: "online_payment_paid",
      auditable: payment,
      metadata: {
        amount: payment.amount,
        stripe_checkout_session_id: payment.stripe_checkout_session_id,
        stripe_payment_intent_id: payment.stripe_payment_intent_id,
        stripe_payment_method_type: payment.stripe_payment_method_type
      }
    )
  end

  def find_payment_from_session(session)
    MembershipPayment.find_by(stripe_checkout_session_id: session.id) ||
      MembershipPayment.find_by(id: session.metadata&.membership_payment_id)
  end

  def find_payment_from_intent(payment_intent)
    MembershipPayment.find_by(stripe_payment_intent_id: payment_intent.id) ||
      MembershipPayment.find_by(id: payment_intent.metadata&.membership_payment_id)
  end

  def payment_method_type_from_payment_intent(payment_intent)
    payment_intent.payment_method_types&.first || payment_intent.payment_method_options&.to_h&.keys&.first
  end
end
