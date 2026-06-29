class WelfareCaseAssigner
  def self.call(welfare_case, assignee:, actor:)
    new(welfare_case, assignee: assignee, actor: actor).call
  end

  def initialize(welfare_case, assignee:, actor:)
    @welfare_case = welfare_case
    @assignee = assignee
    @actor = actor
  end

  def call
    WelfareCase.transaction do
      welfare_case.update!(
        assigned_to: assignee,
        status: next_status
      )
      NotificationCreator.welfare_case_assigned(welfare_case, actor: actor)
      NotificationCreator.welfare_case_updated(welfare_case, actor: actor)
    end

    welfare_case
  end

  private

  attr_reader :welfare_case, :assignee, :actor

  def next_status
    welfare_case.submitted? ? :reviewing : welfare_case.status
  end
end
