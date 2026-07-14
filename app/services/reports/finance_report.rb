module Reports
  class FinanceReport
    attr_reader :start_date, :end_date

    def initialize(start_date: nil, end_date: nil)
      requested_start = parse_date(start_date) || Date.current.beginning_of_year
      requested_end = parse_date(end_date) || Date.current
      @start_date, @end_date = [ requested_start, requested_end ].minmax
    end

    def summary
      return @summary if defined?(@summary)

      total_income = transactions.income.sum(:amount)
      total_expense = transactions.expense.sum(:amount)

      @summary ||= {
        total_income: total_income,
        total_expense: total_expense,
        period_net: total_income - total_expense,
        current_balance: FinanceTransaction.approved_income_total - FinanceTransaction.approved_expense_total,
        transaction_count: transactions.count,
        trend: trend,
        category_breakdown: category_breakdown,
        recent_transactions: transactions.includes(:finance_category, :recorded_by).latest.limit(10)
      }
    end

    def transactions
      @transactions ||= FinanceTransaction.approved.where(transaction_date: start_date..end_date)
    end

    def to_csv
      ReportCsvExporter.call(
        bom: true,
        headers: [
          "Transaction ID", "Transaction Date", "Type", "Category", "Description",
          "Amount (JPY)", "Status", "Reference Number", "Recorded By", "Approved By"
        ],
        rows: transactions.includes(:finance_category, :recorded_by, :approved_by).latest.map do |transaction|
          [
            transaction.id,
            transaction.transaction_date.iso8601,
            transaction.transaction_type.humanize,
            transaction.finance_category.name,
            transaction.description,
            whole_yen(transaction.amount),
            transaction.status.humanize,
            transaction.reference_number,
            transaction.recorded_by.display_name,
            transaction.approved_by&.display_name
          ]
        end
      )
    end

    private

    def trend
      month_starts = []
      cursor = start_date.beginning_of_month
      while cursor <= end_date.beginning_of_month
        month_starts << cursor
        cursor = cursor.next_month
      end
      month_starts = month_starts.last(12)

      income = monthly_totals(transactions.income)
      expense = monthly_totals(transactions.expense)

      month_starts.map do |month|
        {
          label: month.strftime(month_starts.size > 9 ? "%b" : "%b %Y"),
          income: whole_yen(income.fetch(month, 0)),
          expense: whole_yen(expense.fetch(month, 0))
        }
      end
    end

    def monthly_totals(scope)
      scope
        .group("DATE_TRUNC('month', transaction_date)")
        .sum(:amount)
        .transform_keys { |month| month.to_date.beginning_of_month }
    end

    def category_breakdown
      transactions
        .joins(:finance_category)
        .group("finance_categories.name", :transaction_type)
        .sum(:amount)
        .map do |(name, transaction_type), amount|
          type = transaction_type.is_a?(Integer) ? FinanceTransaction.transaction_types.key(transaction_type) : transaction_type.to_s
          {
            name: name,
            type: type,
            amount: whole_yen(amount)
          }
        end
        .sort_by { |item| [ item[:type], -item[:amount] ] }
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end

    def whole_yen(amount)
      BigDecimal(amount.to_s).to_i
    end
  end
end
