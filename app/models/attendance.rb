class Attendance < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :checked_in_by, class_name: "User", optional: true

  before_validation :assign_checked_in_at, if: -> { checked_in_at.blank? }

  validates :user_id, uniqueness: { scope: :event_id }
  validates :checked_in_at, presence: true

  private

  def assign_checked_in_at
    self.checked_in_at = Time.current
  end
end
