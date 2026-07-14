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
      assert_not_includes response.body, "Print A4"

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

      assert response.body.start_with?("\uFEFF")
      rows = CSV.parse(response.body.delete_prefix("\uFEFF"))
      assert_equal [ "MSJ Member Community Report" ], rows[0]
      assert_equal "Generated At", rows[1][0]
      assert_equal [ "COMMUNITY SUMMARY" ], rows[6]
      assert_equal [ "Account Holder Profiles", MemberProfile.count.to_s ], rows[7]
      assert_equal "Registered Spouses", rows[11][0]
      assert_equal FamilyMember.where("LOWER(relationship) = ?", "spouse").count.to_s, rows[11][1]
      assert_equal "Registered Children", rows[12][0]
      assert_equal FamilyMember.where("LOWER(relationship) = ?", "child").count.to_s, rows[12][1]
      assert_equal "GENDER - ACCOUNT HOLDERS", rows[15][0]
      assert_equal "FAMILY STATUS - ACCOUNT HOLDERS", rows[20][0]
      assert_equal "AGE GROUPS - ACCOUNT HOLDERS", rows[25][0]
      directory_index = rows.index([ "MEMBER DIRECTORY" ])
      assert directory_index
      assert_equal [
        "Membership Number", "Full Name", "Account Role", "Email", "Mobile Number", "Gender",
        "Date of Birth", "Age", "Family Status", "Spouse Name", "Children", "Household Size",
        "Father's Name", "Mother's Name", "Status", "Full Address", "Joined On", "Profile Completion"
      ], rows[directory_index + 2]
      president_row = rows.find { |row| row[0] == @president.member_profile.membership_number }
      assert_equal (1 + @president.member_profile.family_members.count).to_s, president_row[11]
      assert_includes president_row[10], "Child Report"
      assert_equal "100%", president_row[17]
    end

    test "member report renders community analysis directory and A4 print control" do
      sign_in @president

      get members_admin_reports_path

      assert_response :success
      assert_select "body.members-report-page"
      assert_select "[data-controller='report-print']"
      assert_select "button[data-action='click->report-print#open']", text: /Print A4/
      assert_select ".members-report-sheet"
      assert_select ".members-report-summary > div", count: 5
      assert_select "[aria-label='Member age distribution chart']"
      assert_select ".members-report-directory-table table"
      assert_select ".members-report-directory-cards"
      assert_select "nav[aria-label='Table pagination']"
      assert_select "select[name='per_page'] option[selected]", text: "25"
      assert_includes response.body, "Household Reach"
      assert_includes response.body, "Data Quality"
      assert_includes response.body, "Member Directory"
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
      assert_equal "text/csv", response.media_type
      assert response.body.start_with?("\uFEFF")
      rows = CSV.parse(response.body.delete_prefix("\uFEFF"))
      assert_equal [ "MSJ Finance Report" ], rows[0]
      assert_equal [ "Reporting Period", Date.current.beginning_of_year.iso8601, Date.current.iso8601 ], rows[1]
      assert_equal "Generated At", rows[2][0]
      assert_equal [ "Currency", "JPY" ], rows[3]
      assert_equal [ "Basis", "Approved transactions only" ], rows[4]
      assert_equal [ "Transaction Count", "2" ], rows[5]
      assert_equal [ "Period Income", "12500" ], rows[6]
      assert_equal [ "Period Expense", "3200" ], rows[7]
      assert_equal [ "Period Net", "9300" ], rows[8]
      assert_equal "Current Balance (All Time)", rows[9][0]
      assert_empty rows[10]
      assert_equal [
        "Date", "Type", "Category", "Amount (JPY)", "Status", "Reference",
        "Description", "Recorded By", "Approved By"
      ], rows[11]
    end

    test "finance report renders professional summary chart and A4 print control" do
      sign_in @president

      get finance_admin_reports_path

      assert_response :success
      assert_select "body.finance-report-page"
      assert_select "[data-controller='report-print']"
      assert_select "button[data-action='click->report-print#open']", text: /Print A4/
      assert_select ".app-mobile-nav"
      assert_select ".finance-report-chart.overflow-hidden"
      assert_select ".finance-report-chart > .flex-col"
      assert_select "svg[aria-label='Monthly income and expense chart']"
      assert_select "nav[aria-label='Table pagination']"
      assert_select "select[name='per_page'] option[selected]", text: "25"
      assert_includes response.body, "Period Income"
      assert_includes response.body, "Period Expense"
      assert_includes response.body, "Period Net"
      assert_includes response.body, "All-time Balance"
      assert_includes response.body, "Approved Transactions"
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
