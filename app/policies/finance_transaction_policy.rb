class FinanceTransactionPolicy < ApplicationPolicy
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

  def approve?
    finance_approver?
  end

  def reject?
    finance_approver?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.finance_viewer? ? scope.all : scope.none
    end
  end
end
