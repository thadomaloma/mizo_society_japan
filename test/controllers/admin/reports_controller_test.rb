require "test_helper"

module Admin
  class ReportsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @president = users(:admin)
      ensure_profile_for(@president)
      @journal_secretary = create_user("Journal Report", "journal_report@example.test", :journal_secretary)
      @executive_member = create_user("Executive Report", "executive_report@example.test", :executive_member)
      @vice_president = create_user("Vice President Report", "vp_report@example.test", :vice_president)
    end

    test "vice president can view reports but cannot export csv" do
      sign_in @vice_president

      get admin_reports_path
      assert_response :success

      get finance_admin_reports_path
      assert_response :success
      assert_not_includes response.body, "Export CSV"

      get finance_admin_reports_path(format: :csv)
      assert_redirected_to root_path
    end

    test "journal secretary can view reports but cannot export csv" do
      sign_in @journal_secretary

      get members_admin_reports_path
      assert_response :success
      assert_not_includes response.body, "Export CSV"

      get members_admin_reports_path(format: :csv)
      assert_redirected_to root_path
    end

    test "executive member can view reports but cannot export csv" do
      sign_in @executive_member

      get events_admin_reports_path
      assert_response :success
      assert_not_includes response.body, "Export CSV"

      get events_admin_reports_path(format: :csv)
      assert_redirected_to root_path
    end

    test "member cannot access reports" do
      member = create_user("Member Report", "member_report@example.test", :member)
      sign_in member

      get admin_reports_path
      assert_redirected_to root_path
    end

    test "authorized admin can export csv" do
      sign_in @president

      get members_admin_reports_path(format: :csv)

      assert_response :success
      assert_includes response.media_type, "text/csv"
    end

    private

    def create_user(name, email, role)
      user = User.create!(name: name, email: email, password: "password123", role: role)
      ensure_profile_for(user)
      user
    end

    def ensure_profile_for(user)
      return if user.member_profile.present?

      user.create_member_profile!(
        full_name: user.name,
        mobile_number: "09012345678",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo"
      )
    end
  end
end
