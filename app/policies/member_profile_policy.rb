class MemberProfilePolicy < ApplicationPolicy
  def show?
    owns_profile?
  end

  def setup?
    owns_profile?
  end

  def update?
    owns_profile?
  end

  private

  def owns_profile?
    user.present? && record.user == user
  end
end
