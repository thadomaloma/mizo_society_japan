class MeetingMinutePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    manage? || (user&.minutes_access? && visible_minute?)
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  def download?
    show? && record.file.attached?
  end

  def publish?
    manage? && record.draft?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.minute_manager?
      return scope.none if user.blank?
      return scope.published if user.minutes_access?

      scope.none
    end
  end

  private

  def manage?
    user&.minute_manager?
  end

  def visible_minute?
    record.published?
  end
end
