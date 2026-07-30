require "test_helper"

class FinanceTransactionTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @category = FinanceCategory.create!(name: "Test Income", category_type: :income, active: true)
  end

  test "amount must be a whole yen amount" do
    transaction = FinanceTransaction.new(
      finance_category: @category,
      recorded_by: @user,
      transaction_type: :income,
      status: :approved,
      amount: BigDecimal("1000.50"),
      transaction_date: Date.current,
      description: "Decimal yen test"
    )

    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "must be a whole yen amount"
  end

  test "amount must be greater than zero" do
    transaction = FinanceTransaction.new(
      finance_category: @category,
      recorded_by: @user,
      amount: 0,
      transaction_date: Date.current,
      description: "Zero yen test"
    )

    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "must be greater than 0"
  end

  test "transaction type follows the selected category" do
    expense_category = FinanceCategory.create!(name: "Test Expense", category_type: :expense, active: true)
    transaction = FinanceTransaction.new(
      finance_category: expense_category,
      recorded_by: @user,
      transaction_type: :income,
      amount: 1000,
      transaction_date: Date.current
    )

    assert transaction.valid?
    assert transaction.expense?
  end

  test "category type cannot change after transactions are recorded" do
    FinanceTransaction.create!(
      finance_category: @category,
      recorded_by: @user,
      amount: 1000,
      transaction_date: Date.current
    )

    assert_not @category.update(category_type: :expense)
    assert_includes @category.errors[:category_type], "cannot be changed after transactions have been recorded"
  end
end
