class EventCategoryPolicy < ApplicationPolicy
  def index?
    event_manager?
  end

  def create?
    event_manager?
  end

  def update?
    event_manager?
  end

  def destroy?
    event_manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      event_manager? ? scope.all : scope.none
    end

    private

    def event_manager?
      user&.event_manager?
    end
  end

  private

  def event_manager?
    user&.event_manager?
  end
end
