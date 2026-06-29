class MembershipPaymentProvisioner
  def self.call(user:, year: Date.current.year)
    new(user: user, year: year).call
  end

  def initialize(user:, year:)
    @user = user
    @year = year
  end

  def call
    return if user.blank?

    RequiredMembershipPaymentProvisioner.call(user: user, year: year)
    provision_legacy_membership_due
  end

  private

  attr_reader :user, :year

  def provision_legacy_membership_due
    return if required_membership_plan_exists?
    return if current_year_payment_exists?

    plan = default_plan
    return if plan.blank?

    MembershipPayment.create!(
      user: user,
      membership_plan: plan,
      amount: plan.amount,
      payment_year: year,
      payment_method: :bank_transfer,
      status: :pending,
      notes: "Automatically generated for online membership payment."
    )
  end

  def required_membership_plan_exists?
    MembershipPlan.active.required_for_members.membership.exists?
  end

  def current_year_payment_exists?
    user.membership_payments.membership_dues.where(payment_year: year).exists?
  end

  def default_plan
    plans = MembershipPlan.active.membership.yearly.order(:amount).to_a
    plans.find { |plan| plan.name.match?(/annual/i) } || plans.first
  end
end
