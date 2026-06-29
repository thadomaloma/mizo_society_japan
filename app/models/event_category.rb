class EventCategory < ApplicationRecord
  has_many :events, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  private

  def normalize_name
    self.name = name.to_s.squish
  end
end
