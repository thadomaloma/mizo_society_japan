class MembershipPaymentsController < ApplicationController
  before_action :set_membership_payment, only: [ :show, :submit_transfer ]
  before_action :set_bank_transfer_details, only: [ :show, :submit_transfer ]

  def index
    authorize MembershipPayment, :member_index?
    MembershipPaymentProvisioner.call(user: current_user)

    @status = params[:status]
    @year = params[:year]
    payment_scope = current_user.membership_payments
      .includes(:family_member, membership_plan: :membership_plan_type)
      .by_year(@year)

    @current_payments = payment_scope
      .current_for_member
      .where(payment_batch_id: nil)
      .latest
      .to_a
    @current_payments.reject! { |payment| settled_payment?(payment) }
    @current_payment_batches = current_user.payment_batches
      .includes(membership_payments: [ :family_member, { membership_plan: :membership_plan_type } ])
      .current_for_member
      .latest
      .to_a
    @current_payment_batches.reject!(&:paid?)
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

  private

  def set_membership_payment
    @membership_payment = current_user.membership_payments.includes(:family_member, membership_plan: :membership_plan_type).find(params[:id])
  end

  def set_bank_transfer_details
    @bank_transfer_details = BankTransferDetails.call
  end

  def bank_transfer_submission_params
    params.require(:membership_payment).permit(
      :transferred_on,
      :transfer_amount,
      :transfer_reference_name,
      :transfer_screenshot
    )
  end

  def settled_payment?(payment)
    settled_payment_keys.include?(payment.settlement_key)
  end

  def settled_payment_plan_ids
    settled_payments
      .reject(&:for_family_member?)
      .map(&:membership_plan_id)
      .uniq
  end

  def settled_payment_keys
    @settled_payment_keys ||= settled_payments.map(&:settlement_key).uniq
  end

  def settled_payments
    @settled_payments ||= current_user.membership_payments
      .includes(:family_member, :membership_plan, :payment_batch)
      .select { |payment| payment.paid? || payment.payment_batch&.paid? }
  end

end
