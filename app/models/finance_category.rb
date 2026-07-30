class FinanceCategory < ApplicationRecord
  has_many :finance_transactions, dependent: :restrict_with_error

  enum :category_type, { income: 0, expense: 1 }

  validates :name, presence: true, uniqueness: { scope: :category_type }
  validates :category_type, presence: true
  validate :category_type_is_immutable_when_used

  scope :active, -> { where(active: true) }
  scope :latest, -> { order(created_at: :desc) }

  private

  def category_type_is_immutable_when_used
    return unless will_save_change_to_category_type?
    return unless finance_transactions.exists?

    errors.add(:category_type, "cannot be changed after transactions have been recorded")
  end
end
