class DocumentPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    manage? || record.downloadable_by?(user)
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

  def publish?
    manage?
  end

  def download?
    show?
  end

  def archive?
    manage?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if can_manage_content?
      return scope.none if user.blank?

      scope.visible_to(user)
    end
  end

  private

  def manage?
    can_manage_content?
  end
end
