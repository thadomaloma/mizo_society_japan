class FinanceTransaction < ApplicationRecord
  belongs_to :finance_category
  belongs_to :recorded_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  enum :transaction_type, { income: 0, expense: 1 }
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_date, presence: true
  validates :transaction_type, :status, presence: true
  validate :category_matches_transaction_type

  before_validation :assign_transaction_date, if: -> { transaction_date.blank? }
  before_validation :copy_category_type, if: -> { transaction_type.blank? && finance_category.present? }

  scope :latest, -> { order(transaction_date: :desc, created_at: :desc) }
  scope :income, -> { where(transaction_type: :income) }
  scope :expense, -> { where(transaction_type: :expense) }
  scope :approved, -> { where(status: :approved) }
  scope :pending, -> { where(status: :pending) }
  scope :this_month, -> { where(transaction_date: Date.current.all_month) }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :by_type, ->(type) { transaction_types.key?(type.to_s) ? where(transaction_type: type) : all }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    left_joins(:finance_category)
      .where(
        "finance_transactions.description ILIKE :query OR finance_transactions.reference_number ILIKE :query OR finance_categories.name ILIKE :query",
        query: pattern
      )
  }

  def self.approved_income_total
    approved.income.sum(:amount)
  end

  def self.approved_expense_total
    approved.expense.sum(:amount)
  end

  def approve!(approver)
    update!(status: :approved, approved_by: approver)
  end

  def reject!(approver)
    update!(status: :rejected, approved_by: approver)
  end

  private

  def assign_transaction_date
    self.transaction_date = Date.current
  end

  def copy_category_type
    self.transaction_type = finance_category.category_type
  end

  def category_matches_transaction_type
    return if finance_category.blank? || transaction_type.blank?

    errors.add(:finance_category, "must match transaction type") unless finance_category.category_type == transaction_type
  end
end
