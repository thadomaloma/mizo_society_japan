require "test_helper"

class Admin::PaymentSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @treasurer = User.create!(
      email: "treasurer@example.test",
      name: "Treasurer User",
      role: :treasurer,
      password: "password123"
    )
    @member = users(:member)
    ensure_profile_for(@treasurer, mobile_number: "08013572468")
    ensure_profile_for(@member, mobile_number: "09024681357")
  end

  test "treasurer can view and update bank details" do
    sign_in @treasurer

    get admin_payment_settings_path
    assert_response :success
    assert_includes response.body, "Bank Details"

    assert_difference -> { AuditLog.where(action: "payment_bank_details_updated").count }, 1 do
      patch admin_payment_settings_path, params: {
        settings: {
          bank_account_name: "Mizo Society of Japan",
          bank_name: "MUFG Bank",
          bank_branch_name: "Shinjuku Branch",
          bank_account_number: "普通 1234567",
          bank_qr_code_url: "https://example.test/bank-qr.png"
        }
      }
    end

    assert_redirected_to admin_payment_settings_path
    assert_equal "MUFG Bank", AppSetting.get("bank_name")
    assert_equal "普通 1234567", AppSetting.get("bank_account_number")
  end

  test "invalid bank qr url is not saved" do
    sign_in @treasurer

    patch admin_payment_settings_path, params: {
      settings: {
        bank_account_name: "Mizo Society of Japan",
        bank_name: "MUFG Bank",
        bank_branch_name: "Shinjuku Branch",
        bank_account_number: "普通 1234567",
        bank_qr_code_url: "not-a-url"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Bank QR Code URL is not valid."
    assert_nil AppSetting.find_by(key: "bank_qr_code_url")
  end

  test "member cannot view bank details admin page" do
    sign_in @member

    get admin_payment_settings_path

    assert_redirected_to root_path
  end

  test "vice president and journal secretary can view bank details but cannot update them" do
    users = [
      User.create!(email: "vp_bank@example.test", name: "Vice President", role: :vice_president, password: "password123"),
      User.create!(email: "journal_bank@example.test", name: "Journal Secretary", role: :journal_secretary, password: "password123")
    ]

    users.each do |user|
      ensure_profile_for(user, mobile_number: "07024681359")
      sign_in user

      get admin_payment_settings_path

      assert_response :success
      assert_includes response.body, "Bank Details"
      assert_not_includes response.body, "Save Bank Details"

      patch admin_payment_settings_path, params: { settings: { bank_name: "Blocked Bank" } }

      assert_redirected_to root_path
      assert_not_equal "Blocked Bank", AppSetting.get("bank_name")
      sign_out user
    end
  end

  test "finance dashboard links to bank details" do
    sign_in @treasurer

    get admin_dashboard_path

    assert_response :success
    assert_select "a[href='#{admin_payment_settings_path}']", text: /Bank Details/
  end

  private

  def ensure_profile_for(user, mobile_number:)
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
