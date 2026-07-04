require "test_helper"

class Admin::UserRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08013572468")
  end

  test "president can view user roles" do
    sign_in @president

    get admin_user_roles_path

    assert_response :success
    assert_includes response.body, "User Roles"
    assert_includes response.body, @member.email
  end

  test "member cannot view user roles" do
    sign_in @member

    get admin_user_roles_path

    assert_redirected_to root_path
  end

  test "president can open add user page" do
    sign_in @president

    get new_admin_user_role_path

    assert_response :success
    assert_includes response.body, "Add User"
  end

  test "member cannot open add user page" do
    sign_in @member

    get new_admin_user_role_path

    assert_redirected_to root_path
  end

  test "president can add user and audit the action" do
    sign_in @president

    assert_difference -> { User.count }, 1 do
      assert_difference -> { AuditLog.where(action: "user_created").count }, 1 do
        assert_difference -> { ActionMailer::Base.deliveries.count }, 1 do
          post admin_user_roles_path, params: {
            user: {
              name: "New Office Bearer",
              email: "new_office_bearer@example.test",
              role: "vice_president"
            }
          }
        end
      end
    end

    user = User.find_by!(email: "new_office_bearer@example.test")
    assert_redirected_to admin_user_roles_path
    assert_equal "vice_president", user.role
    assert_equal "new_office_bearer@example.test", AuditLog.last.metadata["user_email"]
    assert_equal "vice_president", AuditLog.last.metadata["role"]
  end

  test "president can change role and audit the change" do
    sign_in @president

    assert_difference -> { AuditLog.where(action: "user_role_changed").count }, 1 do
      patch admin_user_role_path(@member), params: { user: { role: "executive_member" } }
    end

    assert_redirected_to admin_user_roles_path
    assert_equal "executive_member", @member.reload.role
    assert_equal "member", AuditLog.last.metadata["previous_role"]
    assert_equal "executive_member", AuditLog.last.metadata["new_role"]
  end

  test "president can edit user details" do
    sign_in @president

    assert_difference -> { AuditLog.where(action: "user_updated").count }, 1 do
      patch admin_user_role_path(@member), params: {
        user: { name: "Updated Member", email: "updated_member@example.test", role: "member" }
      }
    end

    assert_redirected_to admin_user_roles_path
    @member.reload
    assert_equal "Updated Member", @member.name
    assert_equal "updated_member@example.test", @member.email
    assert_equal "Updated Member", @member.member_profile.full_name
    assert_equal "Updated Member", @member.display_name
  end

  test "president can deactivate and reactivate another user" do
    sign_in @president

    assert_difference -> { AuditLog.where(action: "user_deactivated").count }, 1 do
      patch deactivate_admin_user_role_path(@member)
    end

    assert_redirected_to admin_user_roles_path
    assert_not @member.reload.active?

    assert_difference -> { AuditLog.where(action: "user_reactivated").count }, 1 do
      patch reactivate_admin_user_role_path(@member)
    end

    assert @member.reload.active?
  end

  test "president cannot deactivate own account or remove the last active super admin role" do
    sign_in @president

    patch deactivate_admin_user_role_path(@president)
    assert_redirected_to admin_user_roles_path
    assert @president.reload.active?

    patch admin_user_role_path(@president), params: { user: { role: "member" } }
    assert_redirected_to admin_user_roles_path
    assert_equal "president", @president.reload.role
  end

  private

  def ensure_profile_for(user, mobile_number: "09024681357")
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: mobile_number,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end
end
