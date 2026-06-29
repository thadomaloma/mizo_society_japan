class WelfareAttachmentPolicy < ApplicationPolicy
  def destroy?
    welfare_user? || owner_uploaded_attachment?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.welfare_viewer?

      scope.joins(:welfare_case).where(welfare_cases: { user_id: user&.id })
    end
  end

  private

  def owner_uploaded_attachment?
    record.uploaded_by_id == user&.id && WelfareCasePolicy.new(user, record.welfare_case).update?
  end
end
