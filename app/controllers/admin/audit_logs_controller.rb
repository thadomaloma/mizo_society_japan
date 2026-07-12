module Admin
  class AuditLogsController < ApplicationController
    before_action :set_audit_log, only: :show

    def index
      authorize AuditLog
      @action_query = params[:action_query]
      @user_query = params[:user_query]
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      filtered_logs = policy_scope(AuditLog)
        .includes(:user, :auditable)
        .search_action(@action_query)
        .search_user(@user_query)
        .from_date(@start_date)
        .to_date(@end_date)
        .latest
      @audit_logs = paginate_relation(filtered_logs)
    end

    def show
      authorize @audit_log
    end

    private

    def set_audit_log
      @audit_log = policy_scope(AuditLog).includes(:user, :auditable).find(params[:id])
    end
  end
end
