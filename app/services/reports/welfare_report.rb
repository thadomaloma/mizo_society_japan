module Reports
  class WelfareReport
    def initialize(scope: WelfareCase.all)
      @scope = scope
    end

    def summary
      {
        open_cases: scope.open_cases.count,
        urgent_cases: scope.open_cases.urgent.count,
        resolved_cases: scope.resolved.count,
        by_category: by_category,
        by_status: scope.group(:status).count,
        recent_cases: scope.includes(:welfare_category, :user, :assigned_to).latest.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        headers: [ "Case ID", "Member", "Category", "Priority", "Status", "Assigned To", "Submitted At", "Resolved At" ],
        rows: scope.includes(:welfare_category, :user, :assigned_to).latest.map do |welfare_case|
          [
            welfare_case.id,
            welfare_case.user.display_name,
            welfare_case.welfare_category.name,
            welfare_case.priority,
            welfare_case.status,
            welfare_case.assigned_to&.display_name,
            welfare_case.submitted_at,
            welfare_case.resolved_at
          ]
        end
      )
    end

    private

    attr_reader :scope

    def by_category
      scope
        .joins(:welfare_category)
        .group("welfare_categories.name")
        .count
    end
  end
end
