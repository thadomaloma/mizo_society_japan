class VolunteerSignupPolicy < ApplicationPolicy
  def show?
    event_user? || owns_signup?
  end

  def create?
    owns_signup? && record.volunteer_slot.open? && record.volunteer_slot.available_spots.positive?
  end

  def update?
    event_user? || owns_signup?
  end

  def destroy?
    event_user? || owns_signup?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.event_team?

      scope.where(user: user)
    end
  end

  private

  def owns_signup?
    record.respond_to?(:user_id) && record.user_id == user&.id
  end
end
