class MembershipPaymentsController < ApplicationController
  before_action :set_membership_payment, only: [ :show, :checkout, :submit_transfer, :success, :cancel ]
  before_action :set_bank_transfer_details, only: [ :show, :submit_transfer, :cancel ]

  def index
    authorize MembershipPayment, :member_index?
    MembershipPaymentProvisioner.call(user: current_user)

    @status = params[:status]
    @year = params[:year]
    payment_scope = current_user.membership_payments
      .includes(membership_plan: :membership_plan_type)
      .by_year(@year)

    @current_payments = payment_scope
      .current_for_member
      .latest
      .to_a
    @current_payments.reject! { |payment| settled_payment_plan?(payment) }
    @current_payment_batches = current_user.payment_batches
      .includes(membership_payments: { membership_plan: :membership_plan_type })
      .pending_verification
      .latest
      .to_a
    active_batch_payment_ids = @current_payment_batches.flat_map { |batch| batch.membership_payments.map(&:id) }
    @current_payments.reject! { |payment| active_batch_payment_ids.include?(payment.id) }
    @payment_history = payment_scope
      .history_for_member
      .by_status(@status)
      .latest
      .to_a
    @years = current_user.membership_payments.distinct.order(payment_year: :desc).pluck(:payment_year)
    @history_status_options = MembershipPayment::HISTORY_STATUSES.map(&:to_s)
    current_plan_ids = @current_payments.map(&:membership_plan_id) + @current_payment_batches.flat_map { |batch| batch.membership_payments.map(&:membership_plan_id) }
    @available_payment_plans = MembershipPlan.active
      .member_payable
      .where.not(id: current_plan_ids)
      .where.not(id: settled_payment_plan_ids)
      .includes(:membership_plan_type)
      .order(:name)
  end

  def start
    authorize MembershipPayment, :member_index?
    membership_plan = MembershipPlan.active.member_payable.find(params.require(:membership_plan_id))
    payment = MemberPlanPaymentStarter.call(user: current_user, membership_plan: membership_plan)

    notice = payment.paid? ? "#{membership_plan.name} is already marked as paid." : "#{membership_plan.name} is ready for payment."
    redirect_to membership_payment_path(payment), notice: notice
  end

  def show
    authorize @membership_payment
  end

  def checkout
    authorize @membership_payment
    session = StripeCheckoutSessionCreator.call(membership_payment: @membership_payment, request: request)

    redirect_to session.url, allow_other_host: true
  rescue StripeCheckoutSessionCreator::StripeConfigurationError => error
    redirect_to membership_payment_path(@membership_payment), alert: error.message
  rescue StripeCheckoutSessionCreator::StripeCheckoutError => error
    redirect_to membership_payment_path(@membership_payment), alert: "Online payment could not be started: #{error.message}"
  end

  def submit_transfer
    authorize @membership_payment
    submission = bank_transfer_submission_params

    if submission[:transferred_on].blank? || submission[:transfer_amount].blank? || submission[:transfer_reference_name].blank?
      @membership_payment.assign_attributes(submission.except(:transfer_screenshot))
      @membership_payment.errors.add(:base, "Transfer date, amount, and reference name are required.")
      render :show, status: :unprocessable_entity
      return
    end

    @membership_payment.submit_bank_transfer!(
      transferred_on: submission[:transferred_on],
      transfer_amount: submission[:transfer_amount],
      transfer_reference_name: submission[:transfer_reference_name],
      transfer_screenshot: submission[:transfer_screenshot]
    )
    NotificationCreator.payment_submitted(@membership_payment, actor: current_user)
    PaymentMailer.with(payment: @membership_payment).transfer_submitted.deliver_later
    AuditLogger.call(
      user: current_user,
      action: "membership_payment_transfer_submitted",
      auditable: @membership_payment,
      metadata: {
        amount: @membership_payment.transfer_amount,
        transferred_on: @membership_payment.transferred_on,
        reference_name: @membership_payment.transfer_reference_name
      },
      request: request
    )

    redirect_to membership_payment_path(@membership_payment), notice: "Bank transfer details submitted. Treasurer will verify the payment."
  end

  def success
    authorize @membership_payment
  end

  def cancel
    authorize @membership_payment

    if params[:session_id].present? && @membership_payment.stripe_checkout_session_id == params[:session_id] && !@membership_payment.paid?
      @membership_payment.update!(status: :cancelled, stripe_status: "cancelled")
    end
  end

  private

  def set_membership_payment
    @membership_payment = current_user.membership_payments.includes(membership_plan: :membership_plan_type).find(params[:id])
  end

  def set_bank_transfer_details
    @bank_transfer_details = {
      account_name: AppSetting.get("bank_account_name", "Mizo Society of Japan"),
      bank_name: AppSetting.get("bank_name", "Please set bank name"),
      branch_name: AppSetting.get("bank_branch_name", "Please set branch / store name"),
      account_number: AppSetting.get("bank_account_number", "Please set account number"),
      yucho_symbol: AppSetting.get("yucho_symbol").presence || legacy_yucho_parts.first,
      yucho_number: AppSetting.get("yucho_number").presence || legacy_yucho_parts.second,
      qr_code_url: AppSetting.get("bank_qr_code_url")
    }
  end

  def legacy_yucho_parts
    @legacy_yucho_parts ||= AppSetting.get("yucho_symbol_number").to_s.scan(/\d+/).first(2)
  end

  def bank_transfer_submission_params
    params.require(:membership_payment).permit(
      :transferred_on,
      :transfer_amount,
      :transfer_reference_name,
      :transfer_screenshot
    )
  end

  def settled_payment_plan?(payment)
    settled_payment_plan_ids.include?(payment.membership_plan_id)
  end

  def settled_payment_plan_ids
    @settled_payment_plan_ids ||= begin
      paid_scope = current_user.membership_payments.paid.includes(:membership_plan)
      paid_scope.select do |payment|
        payment.one_time_payment? || payment.payment_year == Date.current.year
      end.map(&:membership_plan_id)
    end
  end
end
