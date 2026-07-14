class MemberProfile < ApplicationRecord
  JAPAN_MOBILE_NUMBER_REGEX = /\A0[789]0\d{8}\z/
  RESERVED_MOBILE_NUMBERS = %w[
    07012345678
    08012345678
    09012345678
    07000000000
    08000000000
    09000000000
    07011111111
    08011111111
    09011111111
  ].freeze

  REQUIRED_PROFILE_FIELDS = %i[
    full_name
    mobile_number
    date_of_birth
    family_status
    postal_code
    prefecture
    city
    address_line1
  ].freeze

  belongs_to :user
  has_many :family_members, dependent: :destroy
  has_one_attached :avatar

  accepts_nested_attributes_for :family_members, allow_destroy: true, reject_if: :blank_family_member_name?

  enum :gender, { male: 0, female: 1 }
  enum :family_status, { single: 0, family: 1 }, default: :single
  enum :status, { active: 0, inactive: 1, suspended: 2 }, default: :active

  before_validation :assign_membership_number, if: -> { membership_number.blank? }
  before_validation :assign_joined_on, if: -> { joined_on.blank? }
  before_validation :normalize_mobile_number
  before_validation :clear_household_details_unless_family
  after_save :sync_spouse_family_member, if: :family?
  after_save :remove_family_members_unless_family

  validates :full_name, :mobile_number, :date_of_birth, :family_status, :postal_code, :prefecture, :city, :address_line1, presence: true
  validates :membership_number, presence: true, uniqueness: true
  validates :status, presence: true
  validate :address_line1_includes_street_number
  validate :mobile_number_is_not_placeholder
  validate :family_status_preserves_payment_history
  validate :spouse_name_preserves_payment_history
  validates :mobile_number, format: {
    with: JAPAN_MOBILE_NUMBER_REGEX,
    message: "must be a valid Japan mobile number starting with 070, 080, or 090"
  }, allow_blank: true
  validates :mobile_number, uniqueness: {
    message: "is already used by another member"
  }, allow_blank: true

  scope :latest, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    where(
      "full_name ILIKE :query OR membership_number ILIKE :query OR mobile_number ILIKE :query OR city ILIKE :query OR prefecture ILIKE :query",
      query: pattern
    )
  }

  def self.next_membership_number(year = Date.current.year)
    prefix = "MSJ-#{year}-"
    last_number = where("membership_number LIKE ?", "#{prefix}%")
      .maximum(:membership_number)
      &.split("-")
      &.last
      .to_i

    "#{prefix}#{(last_number + 1).to_s.rjust(4, "0")}"
  end

  def age
    return if date_of_birth.blank?

    today = Date.current
    today.year - date_of_birth.year - (today.yday < date_of_birth.yday ? 1 : 0)
  end

  def full_address
    [ address_line1, address_line2, city, prefecture, postal_code ].compact_blank.join(", ")
  end

  def children
    family_members.select { |member| member.relationship.to_s.casecmp("Child").zero? }
  end

  def child_family_members
    family_members.children
  end

  def spouse_family_member
    family_members.spouses.first
  end

  def ensure_spouse_family_member!
    return unless persisted? && family? && spouse_name.present?

    spouse = spouse_family_member || family_members.build(relationship: "Spouse")
    if spouse.new_record? || spouse.name != spouse_name || spouse.membership_number.blank?
      spouse.update!(name: spouse_name, relationship: "Spouse")
    end
    spouse
  end

  def membership_fee_eligible_children(on: Date.current)
    child_family_members.select { |child| child.membership_fee_eligible?(on: on) }
  end

  def complete?
    REQUIRED_PROFILE_FIELDS.all? { |field| public_send(field).present? }
  end

  def profile_completion_percentage
    completed_count = REQUIRED_PROFILE_FIELDS.count { |field| public_send(field).present? }

    ((completed_count.to_f / REQUIRED_PROFILE_FIELDS.size) * 100).round
  end

  def whatsapp_number
    normalized = mobile_number.to_s.gsub(/\D/, "")
    return if normalized.blank?

    normalized.sub(/\A0/, "81")
  end

  def whatsapp_url
    return if whatsapp_number.blank?

    "https://wa.me/#{whatsapp_number}"
  end

  private

  def assign_membership_number
    self.membership_number = self.class.next_membership_number
  end

  def assign_joined_on
    self.joined_on = Date.current
  end

  def blank_family_member_name?(attributes)
    ActiveModel::Type::Boolean.new.cast(attributes["_destroy"]) ? false : attributes["name"].blank?
  end

  def clear_household_details_unless_family
    self.spouse_name = nil unless family?
  end

  def normalize_mobile_number
    return if mobile_number.blank?

    value = mobile_number.to_s
      .tr("０１２３４５６７８９", "0123456789")
      .strip
      .gsub(/[[:space:]\-ー−()（）]/, "")

    self.mobile_number = if value.start_with?("+81")
      "0#{value.delete_prefix('+81').gsub(/\D/, '')}"
    else
      value.gsub(/\D/, "")
    end
  end

  def address_line1_includes_street_number
    return if address_line1.blank?

    normalized_address = address_line1.to_s.tr("０１２３４５６７８９", "0123456789")
    return if normalized_address.match?(/\d/)

    errors.add(:address_line1, "must include a street or building number")
  end

  def mobile_number_is_not_placeholder
    return if mobile_number.blank?
    return unless mobile_number.match?(JAPAN_MOBILE_NUMBER_REGEX)

    local_part = mobile_number[3..]
    return unless RESERVED_MOBILE_NUMBERS.include?(mobile_number) ||
      repeated_digits?(local_part) ||
      sequential_digits?(local_part)

    errors.add(:mobile_number, "cannot be an example or placeholder number")
  end

  def family_status_preserves_payment_history
    return unless will_save_change_to_family_status? && single?
    return unless family_members.joins(:membership_payments).exists?

    errors.add(:family_status, "cannot be changed to single while a family member has payment history")
  end

  def spouse_name_preserves_payment_history
    return unless will_save_change_to_spouse_name? && spouse_name.blank?
    return unless spouse_family_member&.membership_payments&.exists?

    errors.add(:spouse_name, "cannot be removed while the spouse has payment history")
  end

  def repeated_digits?(value)
    value.chars.uniq.one?
  end

  def sequential_digits?(value)
    ascending = "0123456789"
    descending = ascending.reverse

    ascending.include?(value) || descending.include?(value)
  end

  def sync_spouse_family_member
    if spouse_name.present?
      ensure_spouse_family_member!
    elsif spouse_family_member&.membership_payments&.none?
      spouse_family_member.destroy!
    end
  end

  def remove_family_members_unless_family
    family_members.destroy_all unless family?
  end
end
