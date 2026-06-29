class VolunteerSignup < ApplicationRecord
  belongs_to :volunteer_slot
  belongs_to :user

  enum :status, { signed_up: 0, cancelled: 1, completed: 2 }, default: :signed_up

  validates :user_id, uniqueness: { scope: :volunteer_slot_id }
  validates :status, presence: true

  after_save :refresh_volunteer_slot_count
  after_destroy :refresh_volunteer_slot_count

  private

  def refresh_volunteer_slot_count
    return if destroyed_by_association || volunteer_slot.destroyed?

    volunteer_slot.refresh_assigned_count!
  end
end
