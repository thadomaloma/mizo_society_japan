class AiAssistantPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    index?
  end
end
