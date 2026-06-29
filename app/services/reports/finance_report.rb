module Reports
  class FinanceReport
    def initialize(start_date: nil, end_date: nil)
      @start_date = parse_date(start_date) || Date.current.beginning_of_year
      @end_date = parse_date(end_date) || Date.current
    end

    def summary
      {
        total_income: transactions.income.sum(:amount),
        total_expense: transactions.expense.sum(:amount),
        current_balance: FinanceTransaction.approved_income_total - FinanceTransaction.approved_expense_total,
        monthly_income: FinanceTransaction.approved.this_month.income.sum(:amount),
        monthly_expense: FinanceTransaction.approved.this_month.expense.sum(:amount),
        category_breakdown: category_breakdown,
        recent_transactions: transactions.includes(:finance_category, :recorded_by).latest.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        headers: [ "Date", "Type", "Category", "Amount", "Status", "Reference", "Description" ],
        rows: transactions.includes(:finance_category).latest.map do |transaction|
          [
            transaction.transaction_date,
            transaction.transaction_type,
            transaction.finance_category.name,
            transaction.amount,
            transaction.status,
            transaction.reference_number,
            transaction.description
          ]
        end
      )
    end

    private

    attr_reader :start_date, :end_date

    def transactions
      @transactions ||= FinanceTransaction.approved.where(transaction_date: start_date..end_date)
    end

    def category_breakdown
      transactions
        .joins(:finance_category)
        .group("finance_categories.name", :transaction_type)
        .sum(:amount)
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
