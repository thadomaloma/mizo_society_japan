class ClearIneligibleWelfareCaseAssignees < ActiveRecord::Migration[8.1]
  ELIGIBLE_ROLE_VALUES = [ 0, 1, 4 ].freeze

  def up
    execute <<~SQL.squish
      UPDATE welfare_cases
      SET assigned_to_id = NULL
      WHERE assigned_to_id IN (
        SELECT id
        FROM users
        WHERE role NOT IN (#{ELIGIBLE_ROLE_VALUES.join(", ")}) OR active = FALSE
      )
    SQL
  end

  def down
    # Cleared assignments cannot be restored safely.
  end
end
