class EventRegistration < ApplicationRecord
  belongs_to :event
  belongs_to :user

  enum :status, { going: 0, interested: 1, not_attending: 2, cancelled: 3 }, default: :going

  before_validation :assign_registered_at, if: -> { registered_at.blank? }

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :event_id }

  scope :latest, -> { order(registered_at: :desc, created_at: :desc) }

  private

  def assign_registered_at
    self.registered_at = Time.current
  end
end
