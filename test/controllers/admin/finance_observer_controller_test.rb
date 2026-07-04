require "test_helper"

module Admin
  class FinanceObserverControllerTest < ActionDispatch::IntegrationTest
    setup do
      @vice_president = User.create!(
        name: "Vice President",
        email: "vp_finance_observer@example.test",
        password: "password123",
        role: :vice_president
      )
      ensure_profile_for(@vice_president)
      @journal_secretary = User.create!(
        name: "Journal Secretary",
        email: "journal_finance_observer@example.test",
        password: "password123",
        role: :journal_secretary
      )
      ensure_profile_for(@journal_secretary)
      @member = users(:member)
      ensure_profile_for(@member)
      @plan = MembershipPlan.create!(
        name: "Observer Membership",
        amount: 5000,
        membership_plan_type: membership_plan_types(:membership),
        billing_cycle: :yearly,
        active: true
      )
      @payment = MembershipPayment.create!(user: @member, membership_plan: @plan, amount: 5000, payment_year: Date.current.year)
      finance_category = FinanceCategory.create!(name: "Membership Fee", category_type: :income, active: true)
      @transaction = FinanceTransaction.create!(
        finance_category: finance_category,
        recorded_by: users(:admin),
        transaction_type: :income,
        amount: 5000,
        transaction_date: Date.current,
        description: "Observer test transaction",
        status: :pending
      )
    end

    test "vice president and journal secretary can view payments but not mutate them" do
      [ @vice_president, @journal_secretary ].each do |user|
        sign_in user

      get admin_membership_payments_path
      assert_response :success
      assert_includes response.body, @plan.name
      assert_includes response.body, admin_membership_payment_path(@payment)
      assert_not_includes response.body, "Add Payment"
      assert_not_includes response.body, approve_admin_membership_payment_path(@payment)
      assert_not_includes response.body, edit_admin_membership_payment_path(@payment)

      get admin_membership_payment_path(@payment)
      assert_response :success
      assert_includes response.body, @plan.name
      assert_not_includes response.body, edit_admin_membership_payment_path(@payment)

      get new_admin_membership_payment_path
      assert_redirected_to root_path

      patch approve_admin_membership_payment_path(@payment)
      assert_redirected_to root_path

        sign_out user
      end
    end

    test "vice president and journal secretary can view finance transactions but not mutate them" do
      [ @vice_president, @journal_secretary ].each do |user|
        sign_in user

      get admin_finance_transactions_path
      assert_response :success
      assert_includes response.body, "Membership Fee"
      assert_includes response.body, admin_finance_transaction_path(@transaction)
      assert_not_includes response.body, "New Transaction"
      assert_not_includes response.body, edit_admin_finance_transaction_path(@transaction)

      get admin_finance_transaction_path(@transaction)
      assert_response :success
      assert_includes response.body, "Observer test transaction"
      assert_not_includes response.body, edit_admin_finance_transaction_path(@transaction)

      get new_admin_finance_transaction_path
      assert_redirected_to root_path

      patch approve_admin_finance_transaction_path(@transaction)
      assert_redirected_to root_path

        sign_out user
      end
    end

    private

    def ensure_profile_for(user)
      return if user.member_profile.present?

      suffix = user.email.to_s.bytes.sum.to_s.rjust(4, "0")[-4, 4]
      user.create_member_profile!(
        full_name: user.name,
        mobile_number: "0902468#{suffix}",
        postal_code: "169-0075",
        prefecture: "Tokyo",
        city: "Shinjuku",
        address_line1: "1-1-1 Okubo"
      )
    end
  end
end
