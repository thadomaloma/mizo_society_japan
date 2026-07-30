class PaymentMailer < ApplicationMailer
  def transfer_submitted
    @payment = params[:payment]
    mail(
      to: finance_recipient_emails,
      subject: "MSJ payment pending verification"
    )
  end

  def batch_transfer_submitted
    @payment_batch = params[:payment_batch]
    mail(
      to: finance_recipient_emails,
      subject: "MSJ combined payment pending verification"
    )
  end

  def payment_approved
    @payment = params[:payment]
    mail(to: @payment.user.email, subject: "MSJ payment approved")
  end

  def batch_approved
    @payment_batch = params[:payment_batch]
    mail(to: @payment_batch.user.email, subject: "MSJ combined payment approved")
  end

  def payment_rejected
    @payment = params[:payment]
    mail(to: @payment.user.email, subject: "MSJ payment needs review")
  end

  def batch_rejected
    @payment_batch = params[:payment_batch]
    mail(to: @payment_batch.user.email, subject: "MSJ combined payment needs review")
  end

  private

  def finance_recipient_emails
    User.active.where(role: User::FINANCE_ROLES).pluck(:email)
  end
end
