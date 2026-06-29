class VolunteerSlotPolicy < ApplicationPolicy
  def show?
    event_user? || open_visible_slot?
  end

  def create?
    event_user?
  end

  def update?
    event_user?
  end

  def destroy?
    event_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.event_team?

      scope.open.joins(:event).merge(EventPolicy::Scope.new(user, Event).resolve)
    end
  end

  private

  def open_visible_slot?
    record.open? && EventPolicy.new(user, record.event).show?
  end
end
