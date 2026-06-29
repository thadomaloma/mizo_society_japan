class DocumentCategoryPolicy < ApplicationPolicy
  def index?
    can_manage_content?
  end

  def create?
    can_manage_content?
  end

  def update?
    can_manage_content?
  end

  def destroy?
    can_manage_content?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      can_manage_content? ? scope.all : scope.none
    end
  end
end
