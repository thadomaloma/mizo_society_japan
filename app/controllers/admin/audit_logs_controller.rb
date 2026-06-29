module Admin
  class AuditLogsController < ApplicationController
    before_action :set_audit_log, only: :show

    def index
      authorize AuditLog
      @action = params[:action_name]
      @user_id = params[:user_id]
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @audit_logs = policy_scope(AuditLog)
        .includes(:user, :auditable)
        .by_action(@action)
        .by_user(@user_id)
        .from_date(@start_date)
        .to_date(@end_date)
        .latest
        .limit(100)
      @users = User.order(:name, :email)
      @actions = AuditLog.action_options
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
