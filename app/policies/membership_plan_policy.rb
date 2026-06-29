class MembershipPlanPolicy < ApplicationPolicy
  def index?
    finance_viewer?
  end

  def show?
    finance_viewer?
  end

  def create?
    finance_user?
  end

  def update?
    finance_user?
  end

  def destroy?
    admin_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      finance_viewer? ? scope.all : scope.none
    end

    private

    def finance_user?
      user&.finance_team?
    end

    def finance_viewer?
      user&.finance_viewer?
    end
  end
end
