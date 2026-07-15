module Admin
  class MembershipPaymentsController < ApplicationController
    before_action :set_membership_payment, only: [ :show, :edit, :update, :destroy, :approve, :reject, :mark_receipt_whatsapp_opened, :mark_receipt_sent ]
    before_action :set_form_collections, only: [ :new, :create, :edit, :update ]
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_duplicate_payment_record

    def index
      authorize MembershipPayment
      @status = params[:status].presence || "all"
      @year = params[:year]
      @plan_type_id = params[:plan_type_id]
      @query = params[:query]
      filtered_payments = policy_scope(MembershipPayment)
        .includes(*receipt_associations)
        .merge(visible_payment_records)
        .search(@query)
        .by_year(@year)
        .by_plan_type(@plan_type_id)
        .latest
      if @status == "pending_verification"
        filtered_payments = filtered_payments.by_status(@status).where(payment_batch_id: nil)
      elsif @status == "all"
        filtered_payments = filtered_payments.where.not(status: :pending_verification).or(
          filtered_payments.pending_verification.where(payment_batch_id: nil)
        )
      else
        filtered_payments = filtered_payments.by_status(@status)
      end
      @payment_batches = policy_scope(PaymentBatch)
        .includes(:user, membership_payments: [ :family_member, { membership_plan: :membership_plan_type } ])
        .reviewable
        .latest
      @payment_batches = PaymentBatch.none unless @status.in?([ "all", "pending_verification" ])
      @payment_summary = {
        total: filtered_payments.count,
        pending: filtered_payments.pending_verification.count + @payment_batches.count,
        paid: filtered_payments.paid.count,
        amount: filtered_payments.sum(:amount) + @payment_batches.sum(:total_amount)
      }
      @membership_payments = paginate_relation(filtered_payments)
      @years = MembershipPayment.distinct.order(payment_year: :desc).pluck(:payment_year)
      @plan_type_options = MembershipPlanType.active.latest
    end

    def show
      authorize @membership_payment
    end

    def new
      @membership_payment = MembershipPayment.new(payment_year: Date.current.year)
      authorize @membership_payment
    end

    def create
      @membership_payment = MembershipPayment.new(membership_payment_params)
      authorize @membership_payment

      if @membership_payment.save
        AuditLogger.call(
          user: current_user,
          action: "membership_payment_created",
          auditable: @membership_payment,
          metadata: membership_payment_metadata(@membership_payment),
          request: request
        )
        redirect_to admin_membership_payment_path(@membership_payment), notice: "Membership payment was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @membership_payment
    end

    def update
      authorize @membership_payment

      if @membership_payment.update(membership_payment_params)
        MembershipPaymentFinanceRecorder.call(payment: @membership_payment, actor: current_user) if @membership_payment.paid?
        AuditLogger.call(
          user: current_user,
          action: "membership_payment_updated",
          auditable: @membership_payment,
          metadata: membership_payment_metadata(@membership_payment),
          request: request
        )
        redirect_to admin_membership_payment_path(@membership_payment), notice: "Membership payment was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @membership_payment
      metadata = membership_payment_metadata(@membership_payment)
      @membership_payment.destroy

      AuditLogger.call(
        user: current_user,
        action: "membership_payment_deleted",
        metadata: metadata,
        request: request
      )
      redirect_to admin_membership_payments_path, notice: "Membership payment was deleted."
    end

    def approve
      authorize @membership_payment, :approve?
      @membership_payment.approve!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "payment_approved",
        auditable: @membership_payment,
        metadata: membership_payment_metadata(@membership_payment),
        request: request
      )
      NotificationCreator.payment_approved(@membership_payment, actor: current_user)
      PaymentMailer.with(payment: @membership_payment).payment_approved.deliver_later

      redirect_back fallback_location: admin_membership_payment_path(@membership_payment), notice: "Membership payment was approved."
    end

    def reject
      authorize @membership_payment, :reject?
      @membership_payment.reject!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "payment_rejected",
        auditable: @membership_payment,
        metadata: membership_payment_metadata(@membership_payment),
        request: request
      )
      PaymentMailer.with(payment: @membership_payment).payment_rejected.deliver_later

      redirect_back fallback_location: admin_membership_payment_path(@membership_payment), notice: "Membership payment was rejected."
    end

    def mark_receipt_whatsapp_opened
      authorize @membership_payment, :mark_receipt_whatsapp_opened?

      unless @membership_payment.receipt_sendable?
        render json: { error: "A paid receipt and valid member WhatsApp number are required." }, status: :unprocessable_entity
        return
      end

      unless @membership_payment.receipt_whatsapp_opened?
        @membership_payment.mark_receipt_whatsapp_opened!(current_user)
        AuditLogger.call(
          user: current_user,
          action: "payment_receipt_whatsapp_opened",
          auditable: @membership_payment,
          metadata: membership_payment_metadata(@membership_payment),
          request: request
        )
      end

      head :no_content
    end

    def mark_receipt_sent
      authorize @membership_payment, :mark_receipt_sent?
      @membership_payment.mark_receipt_sent!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "payment_receipt_sent",
        auditable: @membership_payment,
        metadata: membership_payment_metadata(@membership_payment),
        request: request
      )

      redirect_back fallback_location: admin_membership_payment_path(@membership_payment), notice: "Receipt marked as sent."
    end

    private

    def set_membership_payment
      @membership_payment = MembershipPayment.includes(*receipt_associations).find(params[:id])
    end

    def receipt_associations
      [
        :approved_by,
        :family_member,
        :receipt_whatsapp_opened_by,
        :receipt_sent_by,
        { membership_plan: :membership_plan_type },
        { payment_batch: [ :approved_by, { membership_payments: [ :family_member, { membership_plan: :membership_plan_type } ] } ] },
        { user: :member_profile }
      ]
    end

    def visible_payment_records
      paid_batch_ids = PaymentBatch.paid.select(:id)
      MembershipPayment.where(payment_batch_id: nil).or(MembershipPayment.where(payment_batch_id: paid_batch_ids))
    end

    def set_form_collections
      @users = User.includes(:member_profile).order(:name, :email)
      plans = MembershipPlan.active
      if @membership_payment&.membership_plan_id.present?
        plans = plans.or(MembershipPlan.where(id: @membership_payment.membership_plan_id))
      end
      @membership_plans = plans.includes(:membership_plan_type).order(:name)
      @blocked_payment_memberships = MembershipPayment
        .where(status: MembershipPayment::DUPLICATE_BLOCKING_STATUSES)
        .where(membership_plan_id: @membership_plans.select(:id))
        .where.not(id: @membership_payment&.id)
        .pluck(:user_id, :membership_plan_id, :payment_year, :payment_month)
        .map do |user_id, plan_id, payment_year, payment_month|
          {
            user_id: user_id,
            plan_id: plan_id,
            payment_year: payment_year,
            payment_month: payment_month
          }
        end
    end

    def membership_payment_params
      permitted = params.require(:membership_payment).permit(
        :user_id,
        :membership_plan_id,
        :amount,
        :payment_year,
        :payment_month,
        :payment_method,
        :paid_on,
        :reference_number,
        :notes
      )
      permitted[:status] = params.dig(:membership_payment, :status) if current_user.finance_approver? && action_name == "update"
      permitted
    end

    def membership_payment_metadata(payment)
      {
        member_name: payment.user&.display_name,
        plan_name: payment.membership_plan&.name,
        amount: payment.amount,
        status: payment.status,
        payment_year: payment.payment_year,
        transferred_on: payment.transferred_on,
        transfer_amount: payment.transfer_amount,
        transfer_reference_name: payment.transfer_reference_name,
        reference_number: payment.reference_number
      }
    end

    def handle_duplicate_payment_record
      @membership_payment ||= MembershipPayment.new(membership_payment_params)
      @membership_payment.errors.add(:base, "This member already has an active or paid record for this payment plan and period. Use the existing record instead.")
      set_form_collections
      render @membership_payment.persisted? ? :edit : :new, status: :unprocessable_entity
    end
  end
end
