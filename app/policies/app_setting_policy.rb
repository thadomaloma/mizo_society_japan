class AppSettingPolicy < ApplicationPolicy
  def show?
    admin_user? || user&.office_bearer?
  end

  def update?
    admin_user?
  end

  def payment?
    finance_viewer?
  end

  def update_payment?
    finance_user?
  end
end
