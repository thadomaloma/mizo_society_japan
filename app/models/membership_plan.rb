class MembershipPlan < ApplicationRecord
  belongs_to :membership_plan_type
  has_many :membership_payments, dependent: :restrict_with_error

  enum :billing_cycle, { monthly: 0, yearly: 1, one_time: 2 }, default: :yearly

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :billing_cycle, presence: true
  validates :membership_plan_type, presence: true

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
end
