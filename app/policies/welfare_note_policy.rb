class WelfareNotePolicy < ApplicationPolicy
  def create?
    welfare_user?
  end

  def update?
    welfare_user?
  end

  def destroy?
    welfare_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.welfare_manager? ? scope.all : scope.none
    end
  end
end
