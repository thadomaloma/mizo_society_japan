require "test_helper"

class Admin::FinanceTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @president = users(:admin)
    @expense_category = FinanceCategory.create!(
      name: "Controller Test Expense",
      category_type: :expense,
      active: true
    )
    ensure_profile_for(@president)
  end

  test "new transaction derives type from category and always starts pending" do
    sign_in @president

    assert_difference -> { FinanceTransaction.count }, 1 do
      post admin_finance_transactions_path, params: {
        finance_transaction: {
          finance_category_id: @expense_category.id,
          transaction_type: "income",
          status: "approved",
          amount: "12500",
          transaction_date: Date.current,
          description: "Venue expense"
        }
      }
    end

    transaction = FinanceTransaction.order(:id).last
    assert_redirected_to admin_finance_transaction_path(transaction)
    assert transaction.expense?
    assert transaction.pending?
    assert_nil transaction.approved_by
  end

  test "zero yen transaction is rejected" do
    sign_in @president

    assert_no_difference -> { FinanceTransaction.count } do
      post admin_finance_transactions_path, params: {
        finance_transaction: {
          finance_category_id: @expense_category.id,
          amount: "0",
          transaction_date: Date.current,
          description: "Invalid zero expense"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Amount must be greater than 0"
  end

  private

  def ensure_profile_for(user)
    return if user.member_profile.present?

    user.create_member_profile!(
      full_name: user.name,
      mobile_number: "09024681357",
      date_of_birth: Date.new(1990, 1, 1),
      family_status: :single,
      postal_code: "169-0075",
      prefecture: "Tokyo",
      city: "Shinjuku",
      address_line1: "1-1-1 Okubo"
    )
  end
end
