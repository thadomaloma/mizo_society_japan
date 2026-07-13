class MembershipPlan < ApplicationRecord
  belongs_to :membership_plan_type
  has_many :membership_payments, dependent: :restrict_with_error

  enum :billing_cycle, { monthly: 0, yearly: 1, one_time: 2 }, default: :yearly

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :child_amount, numericality: { greater_than: 0 }, if: :child_fee_enabled?
  validates :billing_cycle, presence: true
  validates :membership_plan_type, presence: true
  validate :child_fee_is_only_for_membership_plans
  validate :amounts_are_whole_yen

  scope :active, -> { where(active: true) }
  scope :required_for_members, -> { where(required_for_members: true) }
  scope :latest, -> { order(created_at: :desc) }
  scope :by_plan_type, ->(plan_type_id) { plan_type_id.present? ? where(membership_plan_type_id: plan_type_id) : all }
  scope :membership, -> { joins(:membership_plan_type).merge(MembershipPlanType.membership) }
  scope :member_payable, -> { joins(:membership_plan_type).merge(MembershipPlanType.active).where(required_for_members: false).where("amount > 0") }

  def self.plan_type_options
    MembershipPlanType.active.latest.pluck(:name, :id)
  end

  def plan_type_label
    membership_plan_type.name
  end

  def membership?
    membership_plan_type.code == "membership"
  end

  def available_for_member_payment?
    active? && amount.to_i.positive?
  end

  def auto_provisionable?
    active? && required_for_members? && amount.to_i.positive?
  end

  def child_fee_amount
    child_amount.presence || amount
  end

  def provisions_child_fees?
    auto_provisionable? && membership? && child_fee_enabled? && child_fee_amount.to_i.positive?
  end

  private

  def child_fee_is_only_for_membership_plans
    return unless child_fee_enabled?
    return if membership?

    errors.add(:child_fee_enabled, "is available only for membership fee plans")
  end

  def amounts_are_whole_yen
    validate_whole_yen(:amount, amount)
    validate_whole_yen(:child_amount, child_amount) if child_amount.present?
  end

  def validate_whole_yen(attribute, value)
    return if BigDecimal(value.to_s).frac.zero?

    errors.add(attribute, "must be a whole yen amount")
  rescue ArgumentError
    errors.add(attribute, "is not a number")
  end
end
