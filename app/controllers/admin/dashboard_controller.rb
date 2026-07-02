module Admin
  class DashboardController < ApplicationController
    def index
      authorize :dashboard, :admin?

      total_users = User.count
      active_profiles = MemberProfile.active.count
      role_counts = User.group(:role).count
      @finance_dashboard_enabled = current_user.finance_viewer?
      visible_welfare_cases = policy_scope(WelfareCase)
      monthly_transactions = FinanceTransaction.approved.this_month
      monthly_income = monthly_transactions.income.sum(:amount)
      monthly_expense = monthly_transactions.expense.sum(:amount)
      current_balance = FinanceTransaction.approved_income_total - FinanceTransaction.approved_expense_total
      new_members_this_month = MemberProfile.active.where(joined_on: Date.current.all_month).count
      draft_minutes = MeetingMinute.draft.count
      payments_to_verify = MembershipPayment.pending_verification.count
      payments_waiting_transfer = MembershipPayment.pending.count

      @stats = [
        { label: "Active Members", value: active_profiles, tone: "red", icon: :members, caption: "#{total_users} total accounts", caption_tone: "text-slate-500 dark:text-slate-300" },
        { label: "New Members", value: new_members_this_month, tone: "blue", icon: :user_plus, caption: "Joined this month", caption_tone: "text-sky-700 dark:text-sky-300" },
        { label: "Open Welfare Cases", value: visible_welfare_cases.open_cases.count, tone: "red", icon: :welfare, caption: "Needs attention", caption_tone: "text-red-700 dark:text-red-300" },
        { label: "Meeting Minutes", value: MeetingMinute.count, tone: "purple", icon: :documents, caption: "#{draft_minutes} awaiting publication", caption_tone: "text-fuchsia-700 dark:text-fuchsia-300" },
        { label: "Upcoming Events", value: Event.published.upcoming.count, tone: "dark", icon: :events, caption: "Published schedule", caption_tone: "text-slate-500 dark:text-slate-300" }
      ]
      if @finance_dashboard_enabled
        @stats.insert(2, { label: "Payment Review", value: payments_to_verify, tone: "amber", icon: :finance, caption: "#{payments_waiting_transfer} waiting transfer", caption_tone: "text-amber-700 dark:text-amber-300" })
      end

      @role_counts = User.roles.keys.index_with { |role| role_counts.fetch(role, 0) }
      official_letters = Document
        .joins(:document_category)
        .where(document_categories: { name: "Official Letters" })
      @latest_documents = official_letters.includes(:document_category, :uploaded_by, file_attachment: :blob).latest.limit(5)
      @recent_meeting_minutes = MeetingMinute.includes(:uploaded_by, file_attachment: :blob).latest.limit(5)
      @pending_meeting_minutes = MeetingMinute.draft.includes(:uploaded_by).latest.limit(5)
      @recent_welfare_cases = visible_welfare_cases.includes(:welfare_category, :user, :assigned_to).latest.limit(5)
      @upcoming_events = Event.published.upcoming.limit(3)
      @pending_verification_payments = if @finance_dashboard_enabled
        MembershipPayment.pending_verification
          .includes({ membership_plan: :membership_plan_type }, user: :member_profile)
          .latest
          .limit(4)
      else
        MembershipPayment.none
      end
      @recent_activities = recent_activities
      @finance_chart = finance_chart
      @membership_payment_summary = membership_payment_summary
      @finance_summary = {
        income: monthly_income,
        expense: monthly_expense,
        balance: current_balance
      }
      @welfare_summary = {
        open: visible_welfare_cases.open_cases.count,
        in_progress: visible_welfare_cases.in_progress.count,
        resolved: visible_welfare_cases.resolved.count
      }
      active_documents = official_letters.active
      @document_stats = {
        total: official_letters.count,
        drafts: official_letters.draft.count,
        published: active_documents.count,
        final_files: official_letters.joins(:file_attachment).count
      }
      @workflow_rows = workflow_rows
    end

    private

    def finance_chart
      dates = (Date.current.beginning_of_month..Date.current).select { |date| (date.day % 5).zero? || date == Date.current }
      month_range = Date.current.beginning_of_month..Date.current
      income_by_date = FinanceTransaction.approved.income.where(transaction_date: month_range).group(:transaction_date).sum(:amount)
      expense_by_date = FinanceTransaction.approved.expense.where(transaction_date: month_range).group(:transaction_date).sum(:amount)
      running_income = 0
      running_expense = 0

      cumulative_totals = month_range.each_with_object({}) do |date, totals|
        running_income += income_by_date.fetch(date, 0)
        running_expense += expense_by_date.fetch(date, 0)
        totals[date] = { income: running_income, expense: running_expense }
      end

      dates.map do |date|
        totals = cumulative_totals.fetch(date, { income: 0, expense: 0 })
        { label: date.strftime("%b %-d"), income: totals[:income].to_i, expense: totals[:expense].to_i }
      end
    end

    def membership_payment_summary
      paid_this_month = MembershipPayment.paid.where(paid_on: Date.current.all_month)

      {
        pending: MembershipPayment.pending.count,
        pending_verification: MembershipPayment.pending_verification.count,
        paid: MembershipPayment.paid.count,
        this_month: MembershipPayment.where(created_at: Date.current.all_month).count,
        pending_amount: MembershipPayment.pending.sum(:amount),
        pending_verification_amount: MembershipPayment.pending_verification.sum(:amount),
        paid_amount: MembershipPayment.paid.sum(:amount),
        this_month_amount: MembershipPayment.where(created_at: Date.current.all_month).sum(:amount),
        paid_this_month: paid_this_month.count,
        paid_this_month_amount: paid_this_month.sum(:amount)
      }
    end

    def recent_activities
      activities = []
      activities += MembershipPayment.latest.limit(2).map do |payment|
        title = if payment.pending_verification?
          "#{payment.user.display_name} submitted bank transfer"
        elsif payment.paid?
          "#{payment.user.display_name} payment approved"
        else
          "#{payment.user.display_name} has a pending #{payment.plan_type_label.downcase} payment"
        end
        { title: title, subtitle: payment.created_at.strftime("%b %d, %Y"), icon: :finance }
      end
      if current_user.super_admin?
        activities += AuditLog.latest.limit(2).map do |audit|
          { title: audit.action.humanize, subtitle: audit.created_at.strftime("%b %d, %Y %H:%M"), icon: :reports }
        end
      end
      activities += WelfareCase.latest.limit(1).map do |welfare_case|
        { title: "Welfare case updated: #{welfare_case.welfare_category.name}", subtitle: welfare_case.updated_at.strftime("%b %d, %Y"), icon: :welfare }
      end
      activities.first(5)
    end

    def workflow_rows
      [
        { area: "Members", roles: "President, secretary", status: "Model ready", tone: "emerald" },
        { area: "Finance", roles: "Treasurer, finance secretary", status: "Active", tone: "emerald" },
        { area: "Official Notices", roles: "Secretary, assistant secretary", status: "Foundation ready", tone: "sky" },
        { area: "Events", roles: "Secretary, assistant secretary", status: "Foundation ready", tone: "sky" },
        { area: "Letters", roles: "Secretary, assistant secretary", status: "Foundation ready", tone: "sky" },
        { area: "Meeting minutes", roles: "President, secretary, assistant secretary", status: "Foundation ready", tone: "sky" },
        { area: "Welfare", roles: "President, secretary, assistant secretary", status: "Active", tone: "emerald" },
        { area: "Reports", roles: "Executive committee", status: "Active", tone: "emerald" }
      ]
    end
  end
end
