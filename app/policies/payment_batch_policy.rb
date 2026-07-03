class PaymentBatchPolicy < ApplicationPolicy
  def show?
    finance_viewer? || owns_record?
  end

  def create?
    user.present?
  end

  def submit_transfer?
    owns_record? && (record.pending? || record.rejected?)
  end

  def approve?
    finance_approver? && record.pending_verification?
  end

  def reject?
    finance_approver? && record.pending_verification?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.finance_viewer?

      scope.where(user: user)
    end
  end

  private

  def owns_record?
    record.respond_to?(:user_id) && record.user_id == user&.id
  end
end
