class ClearNonManagerWelfareCaseAssignees < ActiveRecord::Migration[8.1]
  WELFARE_MANAGER_ROLE_VALUES = [ 0, 1 ].freeze

  def up
    execute <<~SQL.squish
      UPDATE welfare_cases
      SET assigned_to_id = NULL
      WHERE assigned_to_id IN (
        SELECT id
        FROM users
        WHERE role NOT IN (#{WELFARE_MANAGER_ROLE_VALUES.join(", ")}) OR active = FALSE
      )
    SQL
  end

  def down
    # Cleared assignments cannot be restored safely.
  end
end
