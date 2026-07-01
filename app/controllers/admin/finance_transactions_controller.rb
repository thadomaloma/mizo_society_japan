module Admin
  class FinanceTransactionsController < ApplicationController
    before_action :set_finance_transaction, only: [ :show, :edit, :update, :destroy, :approve, :reject ]
    before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

    def index
      authorize FinanceTransaction
      @status = params[:status]
      @transaction_type = params[:transaction_type]
      @query = params[:query]
      @finance_transactions = policy_scope(FinanceTransaction)
        .includes(:finance_category, :recorded_by, :approved_by)
        .search(@query)
        .by_status(@status)
        .by_type(@transaction_type)
        .latest
      @finance_summary = {
        income: @finance_transactions.select(&:income?).sum(&:amount),
        expense: @finance_transactions.select(&:expense?).sum(&:amount),
        pending: @finance_transactions.count(&:pending?)
      }
    end

    def show
      authorize @finance_transaction
    end

    def new
      @finance_transaction = FinanceTransaction.new(recorded_by: current_user, transaction_date: Date.current)
      authorize @finance_transaction
    end

    def create
      @finance_transaction = FinanceTransaction.new(finance_transaction_params)
      @finance_transaction.recorded_by = current_user
      authorize @finance_transaction

      if @finance_transaction.save
        AuditLogger.call(
          user: current_user,
          action: "finance_transaction_created",
          auditable: @finance_transaction,
          metadata: finance_transaction_metadata(@finance_transaction),
          request: request
        )
        redirect_to admin_finance_transaction_path(@finance_transaction), notice: "Finance transaction was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @finance_transaction
    end

    def update
      authorize @finance_transaction

      if @finance_transaction.update(finance_transaction_params)
        AuditLogger.call(
          user: current_user,
          action: "finance_transaction_updated",
          auditable: @finance_transaction,
          metadata: finance_transaction_metadata(@finance_transaction),
          request: request
        )
        redirect_to admin_finance_transaction_path(@finance_transaction), notice: "Finance transaction was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @finance_transaction
      metadata = finance_transaction_metadata(@finance_transaction)
      @finance_transaction.destroy

      AuditLogger.call(
        user: current_user,
        action: "finance_transaction_deleted",
        metadata: metadata,
        request: request
      )
      redirect_to admin_finance_transactions_path, notice: "Finance transaction was deleted."
    end

    def approve
      authorize @finance_transaction, :approve?
      @finance_transaction.approve!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "finance_transaction_approved",
        auditable: @finance_transaction,
        metadata: finance_transaction_metadata(@finance_transaction),
        request: request
      )

      redirect_back fallback_location: admin_finance_transaction_path(@finance_transaction), notice: "Finance transaction was approved."
    end

    def reject
      authorize @finance_transaction, :reject?
      @finance_transaction.reject!(current_user)
      AuditLogger.call(
        user: current_user,
        action: "finance_transaction_rejected",
        auditable: @finance_transaction,
        metadata: finance_transaction_metadata(@finance_transaction),
        request: request
      )

      redirect_back fallback_location: admin_finance_transaction_path(@finance_transaction), notice: "Finance transaction was rejected."
    end

    private

    def set_finance_transaction
      @finance_transaction = FinanceTransaction.find(params[:id])
    end

    def set_form_collections
      @finance_categories = FinanceCategory.active.order(:category_type, :name)
    end

    def finance_transaction_params
      params.require(:finance_transaction).permit(
        :finance_category_id,
        :transaction_type,
        :amount,
        :transaction_date,
        :description,
        :status,
        :reference_number
      )
    end

    def finance_transaction_metadata(transaction)
      {
        category: transaction.finance_category&.name,
        amount: transaction.amount,
        transaction_type: transaction.transaction_type,
        status: transaction.status,
        reference_number: transaction.reference_number
      }
    end
  end
end
