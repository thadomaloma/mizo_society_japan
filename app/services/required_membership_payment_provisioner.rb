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
    scope = User.active
    user.present? ? scope.where(id: user.id) : scope
  end

  def target_plans
    scope = MembershipPlan.active.required_for_members.where("amount > 0")
    membership_plan.present? ? scope.where(id: membership_plan.id) : scope
  end

  def provision(member, plan)
    payment = existing_payment(member, plan)

    if payment.present?
      sync_pending_amount(payment, plan)
    else
      create_payment(member, plan)
    end
  end

  def existing_payment(member, plan)
    scope = member.membership_payments.where(membership_plan: plan)

    case plan.billing_cycle
    when "monthly"
      scope.where(payment_year: year, payment_month: month).first
    when "one_time"
      scope.first
    else
      scope.where(payment_year: year).first
    end
  end

  def create_payment(member, plan)
    MembershipPayment.create!(
      user: member,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: year,
      payment_month: (month if plan.monthly?),
      payment_method: :bank_transfer,
      status: :pending,
      notes: "Automatically generated from a required payment plan."
    )
  end

  def sync_pending_amount(payment, plan)
    return unless payment.status.in?(SYNCABLE_STATUSES)
    return if payment.amount == plan.amount

    payment.update!(amount: plan.amount)
  end
end
