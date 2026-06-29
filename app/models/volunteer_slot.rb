class VolunteerSlot < ApplicationRecord
  belongs_to :event
  has_many :volunteer_signups, dependent: :destroy

  enum :status, { open: 0, filled: 1, closed: 2 }, default: :open

  validates :title, presence: true
  validates :needed_count, numericality: { only_integer: true, greater_than: 0 }
  validates :assigned_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :available, -> { open.where("assigned_count < needed_count") }

  def available_spots
    [ needed_count - assigned_count, 0 ].max
  end

  def full?
    assigned_count >= needed_count
  end

  def signed_up_by?(user)
    return false if user.blank?

    volunteer_signups.signed_up.exists?(user: user)
  end

  def refresh_assigned_count!
    update!(
      assigned_count: volunteer_signups.signed_up.count,
      status: next_status
    )
  end

  private

  def next_status
    return :closed if closed?
    return :filled if volunteer_signups.signed_up.count >= needed_count

    :open
  end
end
