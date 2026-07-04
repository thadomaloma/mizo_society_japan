class WelfareCasePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    welfare_user? || user&.advisory_viewer? || owner?
  end

  def create?
    user.present?
  end

  def admin_create?
    welfare_user?
  end

  def update?
    welfare_user? || owner_editable_case?
  end

  def destroy?
    welfare_user?
  end

  def assign?
    welfare_user?
  end

  def resolve?
    welfare_user? && record.resolvable?
  end

  def reject?
    welfare_user? && record.open?
  end

  def view_internal_notes?
    welfare_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.welfare_viewer?

      scope.where(user: user)
    end
  end

  private

  def owner?
    record.respond_to?(:user_id) && record.user_id == user&.id
  end

  def owner_editable_case?
    owner? && record.editable_by_member?
  end
end
