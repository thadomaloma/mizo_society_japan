class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.jsonb :metadata, null: false, default: {}
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, [ :auditable_type, :auditable_id ]
    add_index :audit_logs, :created_at
  end
end
