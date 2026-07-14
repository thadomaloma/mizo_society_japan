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
          authorize :report, :export?
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
      @profiles = paginate_relation(@report.directory_scope)

      respond_to do |format|
        format.html
        format.csv do
          authorize :report, :export?
          send_data @report.to_csv,
            filename: "msj-member-community-report-#{Date.current}.csv",
            type: "text/csv; charset=utf-8"
        end
      end
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
