class EventRegistrationPolicy < ApplicationPolicy
  def index?
    event_user?
  end

  def show?
    event_user? || owns_registration?
  end

  def create?
    owns_registration? && record.event.registration_open?
  end

  def update?
    event_user? || owns_registration?
  end

  def destroy?
    event_user? || owns_registration?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.event_team?

      scope.where(user: user)
    end
  end

  private

  def owns_registration?
    record.respond_to?(:user_id) && record.user_id == user&.id
  end
end
