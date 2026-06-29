class MembershipPaymentFinanceRecorder
  def self.call(payment:, actor: nil)
    new(payment:, actor:).call
  end

  def initialize(payment:, actor: nil)
    @payment = payment
    @actor = actor
  end

  def call
    return unless payment.paid?

    FinanceTransaction.find_or_create_by!(reference_number: payment.finance_reference_number) do |transaction|
      transaction.finance_category = finance_category
      transaction.recorded_by = actor || system_finance_user || payment.user
      transaction.approved_by = actor if actor&.finance_approver?
      transaction.transaction_type = :income
      transaction.status = :approved
      transaction.amount = payment.amount
      transaction.transaction_date = payment.paid_on&.to_date || Date.current
      transaction.description = "#{payment.plan_type_label} payment: #{payment.membership_plan.name} #{payment.period_label}"
    end
  end

  private

  attr_reader :payment, :actor

  def finance_category
    FinanceCategory.find_or_create_by!(name: finance_category_name, category_type: :income) do |category|
      category.active = true
    end
  end

  def finance_category_name
    payment.membership_due? ? "Membership Fee" : payment.plan_type_label
  end

  def system_finance_user
    User.where(role: User::FINANCE_ROLES).order(:role).first
  end
end
