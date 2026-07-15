module Admin
  class ReportsController < ApplicationController
    def index
      authorize :report, :index?
    end

    def finance
      authorize :report, :finance?
      @report = Reports::FinanceReport.new(start_date: params[:start_date], end_date: params[:end_date])
      @summary = @report.summary
      transaction_scope = @report.transactions.includes(:finance_category, :recorded_by, :approved_by).latest
      @transactions = paginate_relation(transaction_scope)

      respond_to do |format|
        format.html
        format.csv do
          authorize :report, :export_finance?
          AuditLogger.call(
            user: current_user,
            action: "finance_report_exported",
            metadata: {
              format: "csv",
              start_date: @report.start_date,
              end_date: @report.end_date,
              transaction_count: @summary[:transaction_count]
            },
            request: request
          )
          send_data @report.to_csv,
            filename: "msj-finance-report-#{@report.start_date}-to-#{@report.end_date}.csv",
            type: "text/csv; charset=utf-8"
        end
      end
    end

    def members
      authorize :report, :members?
      @report = Reports::MembersReport.new
      @summary = @report.summary
      @directory_filters = {
        query: params[:query].to_s.strip,
        status: params[:status].to_s,
        family_status: params[:family_status].to_s,
        prefecture: params[:prefecture].to_s,
        age_group: params[:age_group].to_s
      }
      @prefecture_options = @report.prefecture_options
      @profiles = paginate_relation(@report.directory_scope(filters: @directory_filters))
      @can_view_member_details = policy(:report).member_details?

      respond_to do |format|
        format.html
        format.csv do
          authorize :report, :export_members?
          AuditLogger.call(
            user: current_user,
            action: "member_report_exported",
            metadata: {
              format: "csv",
              profile_count: @summary[:total_profiles],
              household_population: @summary[:household_population]
            },
            request: request
          )
          send_data @report.to_csv,
            filename: "msj-member-community-report-#{Date.current}.csv",
            type: "text/csv; charset=utf-8"
        end
      end
    end

    def member
      authorize :report, :member_details?
      @member_profile = MemberProfile.includes(:user, :family_members).find(params[:id])
    end

    def events
      authorize :report, :events?
      @report = Reports::EventsReport.new
      @summary = @report.summary

      respond_to do |format|
        format.html
        format.csv do
          authorize :report, :export?
          send_data @report.to_csv, filename: "msj-events-report-#{Date.current}.csv"
        end
      end
    end

    def welfare
      authorize :report, :welfare?
      @report = Reports::WelfareReport.new(scope: policy_scope(WelfareCase))
      @summary = @report.summary

      respond_to do |format|
        format.html
        format.csv do
          authorize :report, :export?
          send_data @report.to_csv, filename: "msj-welfare-report-#{Date.current}.csv"
        end
      end
    end
  end
end
