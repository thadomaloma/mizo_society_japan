class PaymentMailer < ApplicationMailer
  def transfer_submitted
    @payment = params[:payment]
    mail(
      to: User.where(role: User::FINANCE_ROLES).pluck(:email),
      subject: "MSJ payment pending verification"
    )
  end

  def payment_approved
    @payment = params[:payment]
    mail(to: @payment.user.email, subject: "MSJ payment approved")
  end

  def payment_rejected
    @payment = params[:payment]
    mail(to: @payment.user.email, subject: "MSJ payment needs review")
  end
end
