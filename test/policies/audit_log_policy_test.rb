require "test_helper"

class AuditLogPolicyTest < ActiveSupport::TestCase
  test "only president and secretary can view audit logs" do
    allowed_roles = %w[president secretary]

    User::ROLES.each_key do |role|
      user = User.new(role: role)
      policy = AuditLogPolicy.new(user, AuditLog)

      assert_equal allowed_roles.include?(role.to_s), policy.index?, "#{role} index access mismatch"
      assert_equal allowed_roles.include?(role.to_s), policy.show?, "#{role} show access mismatch"
    end
  end

  test "scope returns records only for audit viewer roles" do
    audit_log = AuditLog.create!(user: users(:admin), action: "settings_updated")
    president = User.new(role: :president)
    treasurer = User.new(role: :treasurer)

    assert_includes AuditLogPolicy::Scope.new(president, AuditLog).resolve, audit_log
    assert_empty AuditLogPolicy::Scope.new(treasurer, AuditLog).resolve
  end
end
