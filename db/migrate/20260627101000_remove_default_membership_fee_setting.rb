class RemoveDefaultMembershipFeeSetting < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      DELETE FROM app_settings WHERE key = 'default_membership_fee'
    SQL
  end

  def down
    execute <<~SQL.squish
      INSERT INTO app_settings (key, value, created_at, updated_at)
      VALUES ('default_membership_fee', '5000', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT (key) DO NOTHING
    SQL
  end
end
