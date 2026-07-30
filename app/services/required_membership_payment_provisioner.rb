class RequiredMembershipPaymentProvisioner
  SYNCABLE_STATUSES = %w[pending failed expired cancelled].freeze
  RETIRABLE_CHILD_PAYMENT_STATUSES = %w[pending failed expired].freeze
  CHILD_AGE_CANCELLATION_NOTE = "Cancelled automatically because child fees start at age #{FamilyMember::MEMBERSHIP_FEE_ELIGIBLE_AGE}.".freeze
  CHILD_AGE_REACTIVATION_NOTE = "Reactivated automatically after the child reached age #{FamilyMember::MEMBERSHIP_FEE_ELIGIBLE_AGE}.".freeze

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
    provision_spouse_payment(member, plan) if plan.provisions_spouse_payment?
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

    eligible_children = profile.membership_fee_eligible_children.to_a
    retire_ineligible_child_payments(member, plan, profile, eligible_children)

    eligible_children.each do |child|
      provision_payment(member, plan, family_member: child)
    end
  end

  def retire_ineligible_child_payments(member, plan, profile, eligible_children)
    ineligible_children = profile.child_family_members.to_a - eligible_children
    return if ineligible_children.empty?

    payments_for_period(member, plan)
      .where(family_member: ineligible_children)
      .where(status: RETIRABLE_CHILD_PAYMENT_STATUSES)
      .includes(:payment_batch)
      .find_each do |payment|
        batch = payment.payment_batch
        next if batch.present? && !batch.status.in?(%w[pending rejected])

        notes = append_note(payment.notes, CHILD_AGE_CANCELLATION_NOTE)
        payment.update_columns(
          payment_batch_id: nil,
          status: MembershipPayment.statuses.fetch("cancelled"),
          notes: notes,
          updated_at: Time.current
        )
        reconcile_batch_after_retirement(batch) if batch.present?
      end
  end

  def reconcile_batch_after_retirement(batch)
    remaining_total = MembershipPayment.where(payment_batch_id: batch.id).sum(:amount)
    attributes = { total_amount: remaining_total, updated_at: Time.current }
    attributes[:status] = PaymentBatch.statuses.fetch("cancelled") if remaining_total.zero?
    batch.update_columns(attributes)
  end

  def provision_spouse_payment(member, plan)
    profile = member.member_profile
    return unless profile&.family?

    spouse = profile.ensure_spouse_family_member!
    provision_payment(member, plan, family_member: spouse) if spouse.present?
  end

  def existing_payment(member, plan, family_member:)
    payments_for_period(member, plan).where(family_member: family_member).first
  end

  def payments_for_period(member, plan)
    scope = member.membership_payments.where(membership_plan: plan)
    case plan.billing_cycle
    when "monthly"
      scope.where(payment_year: year, payment_month: month)
    when "one_time"
      scope
    else
      scope.where(payment_year: year)
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
      notes: automatic_payment_note(family_member)
    )
  end

  def sync_pending_amount(payment, expected_amount)
    return unless payment.status.in?(SYNCABLE_STATUSES)

    attributes = {}
    attributes[:amount] = expected_amount if payment.amount != expected_amount
    if payment.cancelled? && payment.notes.to_s.include?(CHILD_AGE_CANCELLATION_NOTE)
      attributes[:status] = :pending
      attributes[:notes] = append_note(payment.notes, CHILD_AGE_REACTIVATION_NOTE)
    end

    payment.update!(attributes) if attributes.any?
  end

  def payment_amount(plan, family_member)
    family_member&.child? ? plan.child_fee_amount : plan.amount
  end

  def automatic_payment_note(family_member)
    return "Automatically generated from a required payment plan." if family_member.blank?
    return "Automatically generated for the spouse under the family account." if family_member.spouse?

    "Automatically generated for an eligible family member aged #{FamilyMember::MEMBERSHIP_FEE_ELIGIBLE_AGE} or older."
  end

  def append_note(existing_notes, note)
    [ existing_notes, note ].compact_blank.uniq.join("\n")
  end
end
