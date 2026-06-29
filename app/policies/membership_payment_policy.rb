class MembershipPaymentPolicy < ApplicationPolicy
  def index?
    finance_viewer?
  end

  def member_index?
    user.present?
  end

  def show?
    finance_viewer? || owns_record?
  end

  def submit_transfer?
    owns_record? && record.bank_transfer_submittable?
  end

  def checkout?
    owns_record? && record.online_checkoutable?
  end

  def success?
    owns_record?
  end

  def cancel?
    owns_record?
  end

  def create?
    finance_user?
  end

  def update?
    finance_user?
  end

  def destroy?
    finance_user?
  end

  def approve?
    finance_approver? && (record.pending? || record.pending_verification?)
  end

  def reject?
    finance_approver? && (record.pending? || record.pending_verification?)
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
