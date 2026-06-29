class AnnouncementRead < ApplicationRecord
  belongs_to :announcement
  belongs_to :user

  before_validation :assign_read_at, if: -> { read_at.blank? }

  validates :read_at, presence: true
  validates :user_id, uniqueness: { scope: :announcement_id }

  private

  def assign_read_at
    self.read_at = Time.current
  end
end
