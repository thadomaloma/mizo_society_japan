class DashboardPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def admin?
    user&.operations_team?
  end
end
