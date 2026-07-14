class FamilyMember < ApplicationRecord
  belongs_to :member_profile
  has_many :membership_payments, dependent: :restrict_with_error

  before_validation :assign_membership_number, if: :needs_membership_number?

  validates :name, presence: true
  validates :relationship, presence: true
  validates :membership_number, uniqueness: true, allow_blank: true

  scope :children, -> { where("LOWER(relationship) = ?", "child") }
  scope :spouses, -> { where("LOWER(relationship) = ?", "spouse") }

  def child?
    relationship.to_s.casecmp("Child").zero?
  end

  def spouse?
    relationship.to_s.casecmp("Spouse").zero?
  end

  def age
    age_on(Date.current)
  end

  def age_on(date)
    return if date_of_birth.blank? || date.blank?

    years = date.year - date_of_birth.year
    birthday = date_of_birth.advance(years: years)
    years - (birthday > date ? 1 : 0)
  end

  def membership_fee_eligible?(on: Date.current)
    child? && age_on(on).to_i >= 14
  end

  private

  def needs_membership_number?
    membership_number.blank? && (child? || spouse?) && member_profile&.membership_number.present?
  end

  def assign_membership_number
    prefix = "#{member_profile.membership_number}-#{spouse? ? 'S' : 'C'}"
    persisted_numbers = member_profile.family_members
      .where.not(id: id)
      .where("membership_number LIKE ?", "#{prefix}%")
      .pluck(:membership_number)
    pending_numbers = member_profile.family_members.target
      .reject { |member| member.equal?(self) || member.marked_for_destruction? }
      .filter_map(&:membership_number)
    last_suffix = (persisted_numbers + pending_numbers)
      .uniq
      .filter_map { |number| number.delete_prefix(prefix).to_i if number.match?(/\A#{Regexp.escape(prefix)}\d+\z/) }
      .max.to_i

    self.membership_number = "#{prefix}#{(last_suffix + 1).to_s.rjust(2, '0')}"
  end
end
