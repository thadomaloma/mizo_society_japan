class FinanceCategory < ApplicationRecord
  has_many :finance_transactions, dependent: :restrict_with_error

  enum :category_type, { income: 0, expense: 1 }

  validates :name, presence: true, uniqueness: { scope: :category_type }
  validates :category_type, presence: true

  scope :active, -> { where(active: true) }
  scope :latest, -> { order(created_at: :desc) }
end
