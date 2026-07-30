class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owns_notification?
  end

  def mark_as_read?
    owns_notification?
  end

  def mark_all_as_read?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.relevant_to(user)
    end
  end

  private

  def owns_notification?
    record.respond_to?(:recipient_id) && record.recipient_id == user&.id
  end
end
