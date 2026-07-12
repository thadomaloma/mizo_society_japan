require "test_helper"
require "csv"

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
      @president.member_profile.update!(
        father_name: "Father Report",
        mother_name: "Mother Report",
        family_status: :family,
        spouse_name: "Spouse Report",
        address_line2: "Room 201"
      )
      @president.member_profile.family_members.create!(name: "Child Report", relationship: "Child")

      sign_in @president

      get members_admin_reports_path(format: :csv)

      assert_response :success
      assert_includes response.media_type, "text/csv"
      assert_includes response.body, "Full Address"
      assert_not_includes response.body, "Postal Code"
      assert_not_includes response.body, "Address Line 1"
      assert_not_includes response.body, "Address Line 2"
      assert_not_includes response.body, "Prefecture"
      assert_not_includes response.body, "City"
      assert_includes response.body, "Father Report"
      assert_includes response.body, "Mother Report"
      assert_includes response.body, "Spouse Report"
      assert_includes response.body, "Child Report"

      rows = CSV.parse(response.body)
      assert_equal [ "MSJ Member Report" ], rows[0]
      assert_equal "Total Member Profiles", rows[2][0]
      assert_equal MemberProfile.count.to_s, rows[2][1]
      assert_equal "Male", rows[5][0]
      assert_equal "Female", rows[6][0]
      assert_equal "Registered Children", rows[10][0]
      assert_equal FamilyMember.where("LOWER(relationship) = ?", "child").count.to_s, rows[10][1]
      assert_empty rows[12]
      assert_equal [
        "Membership Number", "Full Name", "Email", "Mobile Number", "Gender", "Date of Birth", "Age",
        "Father's Name", "Mother's Name", "Family Status", "Spouse Name", "Children", "Status", "Full Address", "Joined On"
      ], rows[13]
    end

    test "finance csv starts with summary totals before transaction rows" do
      income_category = FinanceCategory.create!(name: "CSV Income", category_type: :income, active: true)
      expense_category = FinanceCategory.create!(name: "CSV Expense", category_type: :expense, active: true)
      FinanceTransaction.create!(
        finance_category: income_category,
        recorded_by: @president,
        approved_by: @president,
        transaction_type: :income,
        amount: 12_500,
        transaction_date: Date.current,
        description: "Finance CSV income",
        status: :approved
      )
      FinanceTransaction.create!(
        finance_category: expense_category,
        recorded_by: @president,
        approved_by: @president,
        transaction_type: :expense,
        amount: 3_200,
        transaction_date: Date.current,
        description: "Finance CSV expense",
        status: :approved
      )
      sign_in @president

      get finance_admin_reports_path(format: :csv)

      assert_response :success
      rows = CSV.parse(response.body)
      assert_equal [ "MSJ Finance Report" ], rows[0]
      assert_equal [ "Period", Date.current.beginning_of_year.iso8601, Date.current.iso8601 ], rows[1]
      assert_equal "Total Income", rows[2][0]
      assert_equal "12500.0", rows[2][1]
      assert_equal "Total Expense", rows[3][0]
      assert_equal "3200.0", rows[3][1]
      assert_equal "Current Balance", rows[4][0]
      assert_empty rows[5]
      assert_equal [ "Date", "Type", "Category", "Amount", "Status", "Reference", "Description" ], rows[6]
    end

    private

    def create_user(name, email, role)
      user = User.create!(name: name, email: email, password: "password123", role: role)
      ensure_profile_for(user)
      user
    end

    def ensure_profile_for(user)
      return if user.member_profile.present?

      suffix = user.email.to_s.bytes.sum.to_s.rjust(4, "0")[-4, 4]
      user.create_member_profile!(
        full_name: user.name,
        mobile_number: "0902468#{suffix}",
        date_of_birth: Date.new(1990, 1, 1),
        family_status: :single,
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo"
      )
    end
  end
end
