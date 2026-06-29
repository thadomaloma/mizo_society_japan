class FinanceCategoryPolicy < ApplicationPolicy
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
    finance_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.finance_viewer? ? scope.all : scope.none
    end
  end
end
