class WelfareCaseResolver
  def self.call(welfare_case, actor:)
    new(welfare_case, actor: actor).call
  end

  def initialize(welfare_case, actor:)
    @welfare_case = welfare_case
    @actor = actor
  end

  def call
    unless welfare_case.resolvable?
      welfare_case.errors.add(:base, "Only open welfare cases can be resolved")
      raise ActiveRecord::RecordInvalid, welfare_case
    end

    WelfareCase.transaction do
      welfare_case.update!(
        status: :resolved,
        resolved_at: welfare_case.resolved_at || Time.current
      )
      NotificationCreator.welfare_case_resolved(welfare_case, actor: actor)
      AuditLogger.call(
        user: actor,
        action: "welfare_case_resolved",
        auditable: welfare_case,
        metadata: {
          title: welfare_case.title,
          member_name: welfare_case.user&.display_name,
          category: welfare_case.welfare_category&.name
        }
      )
    end

    welfare_case
  end

  private

  attr_reader :welfare_case, :actor
end
