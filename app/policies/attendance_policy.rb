class AttendancePolicy < ApplicationPolicy
  def create?
    event_user?
  end

  def destroy?
    event_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.event_team? ? scope.all : scope.where(user: user)
    end
  end
end
