class PaymentBatchesController < ApplicationController
  before_action :set_payment_batch, only: [ :show, :submit_transfer ]
  before_action :set_bank_transfer_details, only: [ :show, :submit_transfer ]

  def create
    authorize PaymentBatch

    payments = current_user.membership_payments
      .includes(membership_plan: :membership_plan_type)
      .where(id: selected_payment_ids)
      .select(&:bank_transfer_submittable?)

    if payments.empty?
      redirect_to membership_payments_path, alert: "Select at least one unpaid payment."
      return
    end

    current_user.payment_batches.pending.destroy_all
    payment_batch = current_user.payment_batches.create!(status: :pending)
    payments.each { |payment| payment.update!(payment_batch: payment_batch) }
    payment_batch.update!(total_amount: payments.sum(&:amount))

    redirect_to payment_batch_path(payment_batch), notice: "Combined payment is ready. Transfer once for the total amount."
  end

  def show
    authorize @payment_batch
  end

  def submit_transfer
    authorize @payment_batch
    submission = bank_transfer_submission_params

    if submission[:transferred_on].blank? || submission[:transfer_amount].blank? || submission[:transfer_reference_name].blank?
      @payment_batch.assign_attributes(submission.except(:transfer_screenshot))
      @payment_batch.errors.add(:base, "Transfer date, amount, and reference name are required.")
      render :show, status: :unprocessable_entity
      return
    end

    if BigDecimal(submission[:transfer_amount].to_s) != @payment_batch.total_amount
      @payment_batch.assign_attributes(submission.except(:transfer_screenshot))
      @payment_batch.errors.add(:transfer_amount, "must match the combined payment total.")
      render :show, status: :unprocessable_entity
      return
    end

    @payment_batch.submit_bank_transfer!(
      transferred_on: submission[:transferred_on],
      transfer_amount: submission[:transfer_amount],
      transfer_reference_name: submission[:transfer_reference_name],
      transfer_screenshot: submission[:transfer_screenshot]
    )

    notify_finance_team
    AuditLogger.call(
      user: current_user,
      action: "payment_batch_transfer_submitted",
      auditable: @payment_batch,
      metadata: {
        amount: @payment_batch.transfer_amount,
        item_count: @payment_batch.membership_payments.count,
        transferred_on: @payment_batch.transferred_on,
        reference_name: @payment_batch.transfer_reference_name
      },
      request: request
    )

    redirect_to payment_batch_path(@payment_batch), notice: "Combined bank transfer submitted. Treasurer will verify the payment."
  end

  private

  def set_payment_batch
    @payment_batch = current_user.payment_batches.includes(membership_payments: { membership_plan: :membership_plan_type }).find(params[:id])
  end

  def selected_payment_ids
    Array(params[:membership_payment_ids]).compact_blank
  end

  def bank_transfer_submission_params
    params.require(:payment_batch).permit(
      :transferred_on,
      :transfer_amount,
      :transfer_reference_name,
      :transfer_screenshot
    )
  end

  def notify_finance_team
    NotificationCreator.create_for_recipients(
      recipients: User.where(role: User::FINANCE_ROLES, active: true),
      actor: current_user,
      notifiable: @payment_batch,
      action: :payment_submitted,
      title: "Combined payment pending verification",
      body: "#{current_user.display_name} submitted #{helpers.yen(@payment_batch.transfer_amount)} for #{@payment_batch.membership_payments.count} payments."
    )
  end

  def set_bank_transfer_details
    @bank_transfer_details = {
      account_name: AppSetting.get("bank_account_name", "Mizo Society of Japan"),
      bank_name: AppSetting.get("bank_name", "Please set bank name"),
      branch_name: AppSetting.get("bank_branch_name", "Please set branch / store name"),
      account_number: AppSetting.get("bank_account_number", "Please set account number"),
      yucho_symbol: yucho_symbol_value,
      yucho_number: yucho_number_value
    }
  end

  def yucho_symbol_value
    explicit_yucho_symbol.presence || inferred_yucho_parts.first
  end

  def yucho_number_value
    explicit_yucho_number.presence || inferred_yucho_parts.second
  end

  def explicit_yucho_symbol
    symbol = AppSetting.get("yucho_symbol").to_s.strip
    return symbol if symbol.blank?

    parts = symbol.scan(/\d+/)
    parts.size >= 2 ? parts.first : symbol
  end

  def explicit_yucho_number
    number = AppSetting.get("yucho_number").to_s.strip
    return number if number.blank?

    parts = number.scan(/\d+/)
    parts.size >= 2 ? parts.second : number
  end

  def inferred_yucho_parts
    @inferred_yucho_parts ||= begin
      symbol = AppSetting.get("yucho_symbol").to_s
      number = AppSetting.get("yucho_number").to_s
      legacy = AppSetting.get("yucho_symbol_number").to_s
      source = [ symbol, number, legacy ].find { |value| value.scan(/\d+/).size >= 2 }.presence || legacy
      source.scan(/\d+/).first(2)
    end
  end
end
