module Admin
  class PaymentBatchesController < ApplicationController
    before_action :set_payment_batch, only: [ :show, :approve, :reject ]

    def show
      authorize @payment_batch
    end

    def approve
      authorize @payment_batch
      @payment_batch.approve!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "payment_batch_approved",
        auditable: @payment_batch,
        metadata: payment_batch_metadata,
        request: request
      )
      NotificationCreator.create_for_recipients(
        recipients: [ @payment_batch.user ],
        actor: current_user,
        notifiable: @payment_batch,
        action: :payment_approved,
        title: "Combined payment approved",
        body: "#{@payment_batch.membership_payments.count} payments have been verified and marked paid."
      )

      redirect_to admin_payment_batch_path(@payment_batch), notice: "Combined payment was approved."
    end

    def reject
      authorize @payment_batch
      @payment_batch.reject!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "payment_batch_rejected",
        auditable: @payment_batch,
        metadata: payment_batch_metadata,
        request: request
      )

      redirect_to admin_payment_batch_path(@payment_batch), notice: "Combined payment was rejected."
    end

    private

    def set_payment_batch
      @payment_batch = policy_scope(PaymentBatch)
        .includes(:user, :approved_by, membership_payments: { membership_plan: :membership_plan_type })
        .find(params[:id])
    end

    def payment_batch_metadata
      {
        member_name: @payment_batch.user&.display_name,
        total_amount: @payment_batch.total_amount,
        transfer_amount: @payment_batch.transfer_amount,
        item_count: @payment_batch.membership_payments.count,
        status: @payment_batch.status
      }
    end
  end
end
