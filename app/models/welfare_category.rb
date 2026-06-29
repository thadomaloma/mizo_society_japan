class WelfareCategory < ApplicationRecord
  has_many :welfare_cases, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
