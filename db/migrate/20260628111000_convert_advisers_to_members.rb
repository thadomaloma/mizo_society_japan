class ConvertAdvisersToMembers < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET role = 7 WHERE role = 9"
  end

  def down
    # Adviser is intentionally retired as a special permission role.
  end
end
