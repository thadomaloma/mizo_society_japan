class UserRolePolicy < ApplicationPolicy
  def index?
    can_manage_roles?
  end

  def update?
    can_manage_roles?
  end

  def create?
    can_manage_roles?
  end

  def deactivate?
    can_manage_roles?
  end

  def reactivate?
    can_manage_roles?
  end
end
