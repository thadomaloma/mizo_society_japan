class WelfareCategoryPolicy < ApplicationPolicy
  def index?
    can_manage_welfare?
  end

  def create?
    can_manage_welfare?
  end

  def update?
    can_manage_welfare?
  end

  def destroy?
    can_manage_welfare?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      can_manage_welfare? ? scope.all : scope.none
    end
  end
end
