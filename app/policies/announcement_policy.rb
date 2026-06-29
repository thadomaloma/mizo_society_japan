class AnnouncementPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    can_manage_content? || visible_to_member?
  end

  def create?
    can_manage_content?
  end

  def update?
    can_manage_content?
  end

  def destroy?
    can_manage_content?
  end

  def publish?
    can_manage_content?
  end

  def archive?
    can_manage_content?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if can_manage_content?

      scope.visible_to_members
    end
  end

  private

  def visible_to_member?
    record.respond_to?(:published?) && record.published? && !record.expired?
  end
end
