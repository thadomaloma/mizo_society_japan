# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  def admin_user?
    can_manage_settings?
  end

  def finance_user?
    can_manage_finance?
  end

  def finance_viewer?
    can_view_finance?
  end

  def finance_approver?
    user&.finance_approver?
  end

  def welfare_user?
    can_manage_welfare?
  end

  def event_user?
    can_manage_content?
  end

  def can_manage_finance?
    user&.finance_team?
  end

  def can_view_finance?
    user&.finance_viewer?
  end

  def can_manage_welfare?
    user&.welfare_manager?
  end

  def can_manage_content?
    user&.event_manager?
  end

  def can_manage_roles?
    user&.super_admin?
  end

  def can_manage_settings?
    user&.super_admin?
  end

  def can_view_audit_logs?
    user&.super_admin?
  end

  def can_view_reports?
    user&.report_viewer?
  end

  def can_view_members?
    user&.super_admin? || user&.finance_admin? || user&.advisory_viewer?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    def can_manage_finance?
      user&.finance_team?
    end

    def can_view_finance?
      user&.finance_viewer?
    end

    def can_manage_welfare?
      user&.welfare_manager?
    end

    def can_manage_content?
      user&.event_manager?
    end

    def can_manage_roles?
      user&.super_admin?
    end

    def can_manage_settings?
      user&.super_admin?
    end

    def can_view_audit_logs?
      user&.super_admin?
    end

    def can_view_reports?
      user&.report_viewer?
    end

    def can_view_members?
      user&.super_admin? || user&.finance_admin? || user&.advisory_viewer?
    end
  end
end
