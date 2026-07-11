require "test_helper"

class Admin::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:member)
    @admin.create_member_profile!(
      full_name: @admin.name,
      mobile_number: "07086420975",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    ) unless @admin.member_profile
  end

  test "audit logs use focused action and user search fields" do
    matching_log = AuditLog.create!(user: @admin, action: "payment_approved")
    AuditLog.create!(user: @member, action: "member_updated")
    sign_in @admin

    get admin_audit_logs_path, params: {
      action_query: "payment",
      user_query: @admin.email.split("@").first
    }

    assert_response :success
    assert_includes response.body, matching_log.action_label
    assert_not_includes response.body, "Member Updated"
    assert_select "input[name=action_query][type=search]"
    assert_select "input[name=user_query][type=search]"
    assert_select "select[name=action_name]", count: 0
    assert_select "select[name=user_id]", count: 0
  end
end
