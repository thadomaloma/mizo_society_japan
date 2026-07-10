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
end
