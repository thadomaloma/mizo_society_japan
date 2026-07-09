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

    transaction = existing_transaction || FinanceTransaction.new(reference_number: payment.finance_reference_number)
    transaction.assign_attributes(transaction_attributes)
    transaction.save!
    transaction
  end

  private

  attr_reader :payment, :actor

  def existing_transaction
    FinanceTransaction.find_by(reference_number: payment.finance_reference_number) ||
      legacy_reference_numbers.filter_map { |reference| FinanceTransaction.find_by(reference_number: reference) }.first
  end

  def transaction_attributes
    {
      finance_category: finance_category,
      recorded_by: actor || system_finance_user || payment.user,
      approved_by: actor&.finance_approver? ? actor : payment.approved_by,
      transaction_type: :income,
      status: :approved,
      amount: payment.amount,
      transaction_date: payment.paid_on&.to_date || Date.current,
      description: "#{payment.plan_type_label} payment: #{payment.membership_plan.name} #{payment.period_label}",
      reference_number: payment.finance_reference_number
    }
  end

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

  def legacy_reference_numbers
    [ payment.transfer_reference_name, payment.reference_number ].compact_blank.uniq
  end
end
