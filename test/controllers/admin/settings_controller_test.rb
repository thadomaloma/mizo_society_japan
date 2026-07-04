require "test_helper"
require "zlib"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @member = users(:member)
    ensure_profile_for(@president)
    ensure_profile_for(@member, mobile_number: "08013572468")
  end

  test "president can view and update settings with an audit record" do
    sign_in @president

    assert_difference -> { AuditLog.where(action: "settings_updated").count }, 1 do
      patch admin_settings_path, params: { settings: valid_settings.merge(organization_name: "Mizo Society Japan Office") }
    end

    assert_redirected_to admin_settings_path
    assert_equal "Mizo Society Japan Office", AppSetting.get("organization_name")
    assert_equal [ "organization_name", "contact_email", "contact_phone", "portal_notice", "maintenance_mode" ].sort,
      AuditLog.last.metadata["changed_keys"].sort
  end

  test "invalid settings are not saved" do
    sign_in @president

    patch admin_settings_path, params: { settings: valid_settings.merge(contact_email: "not-an-email") }

    assert_response :unprocessable_entity
    assert_includes response.body, "Contact email is not valid."
    assert_nil AppSetting.find_by(key: "contact_email")
  end

  test "member cannot view settings" do
    sign_in @member

    get admin_settings_path

    assert_redirected_to root_path
  end

  test "vice president cannot view or update settings" do
    vice_president = User.create!(name: "Vice President", email: "vp_settings@example.test", password: "password123", role: :vice_president)
    ensure_profile_for(vice_president, mobile_number: unique_mobile_for(vice_president))
    sign_in vice_president

    get admin_settings_path
    assert_redirected_to root_path

    patch admin_settings_path, params: { settings: valid_settings.merge(organization_name: "Blocked VP Update") }

    assert_redirected_to root_path
    assert_not_equal "Blocked VP Update", AppSetting.get("organization_name")
  end

  test "new membership plan leaves amount for the payment plan form" do
    sign_in @president

    get new_admin_membership_plan_path

    assert_response :success
    assert_select "input[name='membership_plan[amount]']", 1
    assert_no_match(/name="membership_plan\[amount\]"[^>]+value="7500"/, response.body)
  end

  test "maintenance mode blocks members but keeps super admin access" do
    AppSetting.set("maintenance_mode", "1")

    sign_in @member
    get root_path
    assert_response :service_unavailable
    assert_includes response.body, "The portal is under maintenance."

    sign_out @member
    sign_in @president
    get admin_dashboard_path
    assert_response :success
  end

  private

  def valid_settings
    {
      contact_email: "contact@msj.example",
      contact_phone: "09024681357",
      portal_notice: "Annual meeting registration is open.",
      maintenance_mode: "0"
    }
  end

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

  def unique_mobile_for(user)
    suffix = (Zlib.crc32(user.email) % 100_000_000).to_s.rjust(8, "0")
    "090#{suffix}"
  end
end
