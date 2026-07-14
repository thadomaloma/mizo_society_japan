class ReportPolicy < ApplicationPolicy
  def index?
    can_view_reports?
  end

  def finance?
    user&.super_admin? || user&.finance_admin? || user&.advisory_viewer?
  end

  def members?
    can_view_members?
  end

  def events?
    user&.super_admin? || user&.content_admin? || user&.advisory_viewer?
  end

  def welfare?
    user&.welfare_viewer? || user&.advisory_viewer?
  end

  def export?
    user.present? && !user.advisory_viewer? && (
      user.super_admin? ||
      user.finance_admin? ||
      user.content_admin? ||
      user.welfare_manager?
    )
  end

  def export_finance?
    user&.finance_team? || false
  end

  def export_members?
    user&.super_admin? || false
  end
end
