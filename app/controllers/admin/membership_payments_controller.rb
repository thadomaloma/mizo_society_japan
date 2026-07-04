module Admin
  class MembershipPaymentsController < ApplicationController
    before_action :set_membership_payment, only: [ :show, :edit, :update, :destroy, :approve, :reject ]
    before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

    def index
      authorize MembershipPayment
      @status = params[:status].presence || "all"
      @year = params[:year]
      @plan_type_id = params[:plan_type_id]
      @query = params[:query]
      @membership_payments = policy_scope(MembershipPayment)
        .includes({ membership_plan: :membership_plan_type }, user: :member_profile)
        .search(@query)
        .by_year(@year)
        .by_plan_type(@plan_type_id)
        .latest
      if @status == "pending_verification"
        @membership_payments = @membership_payments.by_status(@status).where(payment_batch_id: nil)
      elsif @status == "all"
        @membership_payments = @membership_payments.where.not(status: :pending_verification).or(
          @membership_payments.pending_verification.where(payment_batch_id: nil)
        )
      else
        @membership_payments = @membership_payments.by_status(@status)
      end
      @payment_batches = policy_scope(PaymentBatch)
        .includes(:user, membership_payments: { membership_plan: :membership_plan_type })
        .reviewable
        .latest
      @payment_batches = PaymentBatch.none unless @status.in?([ "all", "pending_verification" ])
      @payment_summary = {
        total: @membership_payments.count,
        pending: @membership_payments.pending_verification.count + @payment_batches.count,
        paid: @membership_payments.paid.count,
        amount: @membership_payments.sum(&:amount) + @payment_batches.sum(&:total_amount)
      }
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

    private

    def set_membership_payment
      @membership_payment = MembershipPayment.find(params[:id])
    end

    def set_form_collections
      @users = User.includes(:member_profile).order(:name, :email)
      plans = MembershipPlan.active
      if @membership_payment&.membership_plan_id.present?
        plans = plans.or(MembershipPlan.where(id: @membership_payment.membership_plan_id))
      end
      @membership_plans = plans.includes(:membership_plan_type).order(:name)
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
      permitted[:status] = params.dig(:membership_payment, :status) if current_user.finance_approver?
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
  end
end
