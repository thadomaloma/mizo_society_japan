class RequiredMembershipPaymentProvisioner
  SYNCABLE_STATUSES = %w[pending failed expired cancelled].freeze

  def self.call(user: nil, membership_plan: nil, year: Date.current.year, month: Date.current.month)
    new(user: user, membership_plan: membership_plan, year: year, month: month).call
  end

  def initialize(user:, membership_plan:, year:, month:)
    @user = user
    @membership_plan = membership_plan
    @year = year
    @month = month
  end

  def call
    target_users.find_each do |member|
      target_plans.find_each do |plan|
        provision(member, plan)
      end
    end
  end

  private

  attr_reader :user, :membership_plan, :year, :month

  def target_users
    scope = User.active.includes(member_profile: :family_members)
    user.present? ? scope.where(id: user.id) : scope
  end

  def target_plans
    scope = MembershipPlan.active.required_for_members.where("amount > 0")
    membership_plan.present? ? scope.where(id: membership_plan.id) : scope
  end

  def provision(member, plan)
    provision_payment(member, plan)
    provision_child_payments(member, plan) if plan.provisions_child_fees?
  end

  def provision_payment(member, plan, family_member: nil)
    payment = existing_payment(member, plan, family_member: family_member)

    if payment.present?
      sync_pending_amount(payment, payment_amount(plan, family_member))
    else
      create_payment(member, plan, family_member: family_member)
    end
  end

  def provision_child_payments(member, plan)
    profile = member.member_profile
    return unless profile&.family?

    profile.membership_fee_eligible_children.each do |child|
      provision_payment(member, plan, family_member: child)
    end
  end

  def existing_payment(member, plan, family_member:)
    scope = member.membership_payments.where(membership_plan: plan, family_member: family_member)

    case plan.billing_cycle
    when "monthly"
      scope.where(payment_year: year, payment_month: month).first
    when "one_time"
      scope.first
    else
      scope.where(payment_year: year).first
    end
  end

  def create_payment(member, plan, family_member: nil)
    MembershipPayment.create!(
      user: member,
      membership_plan: plan,
      family_member: family_member,
      amount: payment_amount(plan, family_member),
      payment_year: year,
      payment_month: (month if plan.monthly?),
      payment_method: :bank_transfer,
      status: :pending,
      notes: family_member.present? ? "Automatically generated for an eligible family member aged 14 or older." : "Automatically generated from a required payment plan."
    )
  end

  def sync_pending_amount(payment, expected_amount)
    return unless payment.status.in?(SYNCABLE_STATUSES)
    return if payment.amount == expected_amount

    payment.update!(amount: expected_amount)
  end

  def payment_amount(plan, family_member)
    family_member.present? ? plan.child_fee_amount : plan.amount
  end
end
