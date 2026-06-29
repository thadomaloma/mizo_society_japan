class FamilyMember < ApplicationRecord
  belongs_to :member_profile

  validates :name, presence: true
  validates :relationship, presence: true

  def age
    return if date_of_birth.blank?

    today = Date.current
    today.year - date_of_birth.year - (today.yday < date_of_birth.yday ? 1 : 0)
  end
end
