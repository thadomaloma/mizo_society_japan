class MemberPlanPaymentStarter
  def self.call(user:, membership_plan:)
    new(user: user, membership_plan: membership_plan).call
  end

  def initialize(user:, membership_plan:)
    @user = user
    @membership_plan = membership_plan
  end

  def call
    reusable_payment || create_payment!
  end

  private

  attr_reader :user, :membership_plan

  def reusable_payment
    user.membership_payments
      .where(membership_plan: membership_plan, status: MembershipPayment::CURRENT_STATUSES + [ :cancelled ])
      .latest
      .first
  end

  def create_payment!
    MembershipPayment.create!(
      user: user,
      membership_plan: membership_plan,
      amount: membership_plan.amount,
      payment_year: Date.current.year,
      payment_method: :bank_transfer,
      status: :pending,
      notes: "Created from the #{membership_plan.plan_type_label} payment plan."
    )
  end
end
