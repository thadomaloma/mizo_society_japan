class EventPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    event_user? || visible_event?
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

  def publish?
    event_user?
  end

  def cancel?
    event_user?
  end

  def complete?
    event_user?
  end

  def check_attendance?
    event_user?
  end

  def manage_registrations?
    event_user?
  end

  def rsvp?
    user.present? && record.registration_open?
  end

  def withdraw_rsvp?
    user.present? && record.registered_by?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if can_manage_content?

      visible_scope = scope.published.where(visibility: [ :public_event, :members_only ])
      return visible_scope.or(scope.published.where(visibility: :office_bearers_only)) if user&.office_bearer?

      visible_scope
    end
  end

  private

  def visible_event?
    return false unless record.published?
    return true if record.public_event? || record.members_only?

    record.office_bearers_only? && user&.office_bearer?
  end
end
