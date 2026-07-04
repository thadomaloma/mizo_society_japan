require "test_helper"
require "zlib"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "vice president and journal secretary can use admin dashboard shell with view only access" do
      users = [
        User.create!(name: "Vice President", email: "vice_president_dashboard@example.test", password: "password123", role: :vice_president),
        User.create!(name: "Journal Secretary", email: "journal_secretary_dashboard@example.test", password: "password123", role: :journal_secretary)
      ]

      users.each do |user|
        ensure_profile_for(user)
        sign_in user

        get admin_dashboard_path

        assert_response :success
        assert_select "a[aria-label='Go to dashboard'][href='#{admin_dashboard_path}']"
        assert_includes response.body, "Dashboard"
        assert_includes response.body, "Payments"
        assert_includes response.body, "Payment Records"
        assert_includes response.body, "Payment Plans"
        assert_includes response.body, "Transactions"
        assert_includes response.body, "Welfare"
        assert_includes response.body, "Minutes"
        assert_includes response.body, "Events"
        assert_includes response.body, "Letters"
        assert_includes response.body, "Reports"
        assert_includes response.body, 'href="/payments"'
        assert_includes response.body, 'href="/admin/finance_transactions"'
        assert_includes response.body, 'href="/admin/payments"'
        assert_includes response.body, 'href="/admin/welfare_cases"'
        assert_includes response.body, 'href="/events"'
        assert_includes response.body, 'href="/letters"'
        assert_includes response.body, 'href="/admin/reports"'
        assert_not_includes response.body, 'href="/admin/settings"'
        assert_not_includes response.body, 'href="/admin/user_roles"'

        sign_out user
      end
    end

    private

    def ensure_profile_for(user)
      return if user.member_profile.present?

      user.create_member_profile!(
        full_name: user.name,
        mobile_number: unique_mobile_for(user),
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
end
