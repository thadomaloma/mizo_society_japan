require "test_helper"
require "ostruct"

class AuditLoggerTest < ActiveSupport::TestCase
  test "creates audit log with request and metadata context" do
    request = OpenStruct.new(remote_ip: "203.0.113.10", user_agent: "MSJ Test Browser")

    audit_log = nil
    assert_difference -> { AuditLog.count }, 1 do
      audit_log = AuditLogger.call(
        user: users(:admin),
        action: "member_updated",
        auditable: users(:member),
        metadata: { member_name: "Member User", changed_fields: [ :full_name ] },
        request: request
      )
    end

    assert_equal users(:admin), audit_log.user
    assert_equal "member_updated", audit_log.action
    assert_equal users(:member), audit_log.auditable
    assert_equal "203.0.113.10", audit_log.ip_address
    assert_equal "MSJ Test Browser", audit_log.user_agent
    assert_equal "Member User", audit_log.metadata["member_name"]
    assert_equal [ "full_name" ], audit_log.metadata["changed_fields"]
  end
end
