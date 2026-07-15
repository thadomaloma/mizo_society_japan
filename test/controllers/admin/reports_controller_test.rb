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
      @treasurer = create_user("Treasurer Report", "treasurer_report@example.test", :treasurer)
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

    test "treasurer can export finance csv but cannot export confidential member csv" do
      sign_in @treasurer

      get finance_admin_reports_path
      assert_response :success
      assert_includes response.body, "Export CSV"

      assert_difference -> { AuditLog.where(action: "finance_report_exported", user: @treasurer).count }, 1 do
        get finance_admin_reports_path(format: :csv)
      end
      assert_response :success

      get members_admin_reports_path
      assert_response :success
      assert_not_includes response.body, "Export CSV"
      assert_not_includes response.body, "Print A4"

      assert_no_difference -> { AuditLog.where(action: "member_report_exported", user: @treasurer).count } do
        get members_admin_reports_path(format: :csv)
      end
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
      @president.member_profile.family_members.create!(
        name: "Child Report",
        relationship: "Child",
        date_of_birth: Date.new(2012, 3, 4)
      )
      @president.member_profile.family_members.create!(
        name: "Second Child",
        relationship: "Child",
        date_of_birth: Date.new(2015, 6, 7)
      )

      sign_in @president

      assert_difference -> { AuditLog.where(action: "member_report_exported", user: @president).count }, 1 do
        get members_admin_reports_path(format: :csv)
      end

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
      assert_equal [
        "Membership Number", "Full Name", "Account Role", "Member Status", "Joined Date",
        "Mobile Number", "Email Address", "Gender", "Date of Birth", "Age", "Family Status",
        "Spouse Name", "Children Count", "Children Details", "Household Size", "Father's Name",
        "Mother's Name", "Full Address", "Profile Completion (%)"
      ], rows[0]
      assert rows.all? { |row| row.length == rows[0].length }, "every CSV row should match the header width"
      assert_equal MemberProfile.count + 1, rows.length
      president_row = rows.find { |row| row[0] == @president.member_profile.membership_number }
      assert_equal "2", president_row[12]
      child_lines = president_row[13].split("\n")
      assert_equal 2, child_lines.size
      first_child = @president.member_profile.family_members.find_by!(name: "Child Report")
      assert_equal "Child Report | DOB: 2012-03-04 | Age: #{first_child.age}", child_lines[0]
      assert_match(/\ASecond Child \| DOB: 2015-06-07 \| Age: \d+\z/, child_lines[1])
      assert_equal (1 + @president.member_profile.family_members.count).to_s, president_row[14]
      assert_equal "Father Report", president_row[15]
      assert_equal "Mother Report", president_row[16]
      assert_equal "100", president_row[18]

      export_log = AuditLog.where(action: "member_report_exported", user: @president).latest.first
      assert_equal MemberProfile.count, export_log.metadata.fetch("profile_count")
      assert_equal "csv", export_log.metadata.fetch("format")
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
      assert_select "input[name='query']"
      assert_select "select[name='status']"
      assert_select "select[name='family_status']"
      assert_select "select[name='prefecture']"
      assert_select "select[name='age_group']"
      assert_select "a[href='#{admin_member_report_path(@president.member_profile)}']"
      assert_select "nav[aria-label='Table pagination']"
      assert_select "select[name='per_page'] option[selected]", text: "25"
      assert_includes response.body, "Household Reach"
      assert_includes response.body, "Data Quality"
      assert_includes response.body, "Member Directory"
    end

    test "member directory filters profiles by query status household prefecture and age" do
      matching_user = create_user("Filtered Member", "filtered_member@example.test", :member)
      matching_user.member_profile.update!(
        full_name: "Unique Directory Member",
        status: :active,
        family_status: :family,
        spouse_name: "Directory Spouse",
        prefecture: "東京都",
        date_of_birth: 25.years.ago.to_date
      )
      create_user("Different Member", "different_member@example.test", :member)
      sign_in @president

      get members_admin_reports_path, params: {
        query: "Unique Directory",
        status: "active",
        family_status: "family",
        prefecture: "東京都",
        age_group: "18_29"
      }

      assert_response :success
      assert_includes response.body, "Unique Directory Member"
      assert_not_includes response.body, "Different Member"
      assert_select "option[value='18_29'][selected]", text: "18-29"
      assert_select ".members-report-directory", text: /1 matching profile/
    end

    test "office bearer can open confidential member details" do
      sign_in @vice_president

      get admin_member_report_path(@president.member_profile)

      assert_response :success
      assert_includes response.body, @president.member_profile.full_name
      assert_includes response.body, @president.member_profile.mobile_number
      assert_includes response.body, "Registered household"
      assert_includes response.body, "Confidential member information"
    end

    test "executive member cannot open confidential member details" do
      sign_in @executive_member

      get members_admin_reports_path
      assert_response :success
      assert_not_includes response.body, admin_member_report_path(@president.member_profile)
      assert_includes response.body, "Office Bearers only"

      get admin_member_report_path(@president.member_profile)
      assert_redirected_to root_path
    end

    test "finance csv is a clean rectangular transaction dataset" do
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

      assert_difference -> { AuditLog.where(action: "finance_report_exported", user: @president).count }, 1 do
        get finance_admin_reports_path(format: :csv)
      end

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert response.body.start_with?("\uFEFF")
      rows = CSV.parse(response.body.delete_prefix("\uFEFF"))
      assert_equal [
        "Transaction ID", "Transaction Date", "Type", "Category", "Description",
        "Amount (JPY)", "Status", "Reference Number", "Recorded By", "Approved By"
      ], rows[0]
      assert_equal 3, rows.length
      assert rows.all? { |row| row.length == rows[0].length }, "every CSV row should match the header width"
      amount_by_type = rows.drop(1).to_h { |row| [ row[2], row[5] ] }
      assert_equal({ "Income" => "12500", "Expense" => "3200" }, amount_by_type)

      export_log = AuditLog.where(action: "finance_report_exported", user: @president).latest.first
      assert_equal 2, export_log.metadata.fetch("transaction_count")
      assert_equal "csv", export_log.metadata.fetch("format")
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
