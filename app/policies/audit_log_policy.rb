class AuditLogPolicy < ApplicationPolicy
  def index?
    audit_viewer?
  end

  def show?
    audit_viewer?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      audit_viewer? ? scope.all : scope.none
    end

    private

    def audit_viewer?
      can_view_audit_logs?
    end
  end

  private

  def audit_viewer?
    can_view_audit_logs?
  end
end
