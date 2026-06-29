class RefineAuditLogsForSecurityTracking < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:audit_logs, :metadata)
      add_column :audit_logs, :metadata, :jsonb, default: {}, null: false
    end
    add_column :audit_logs, :ip_address, :string unless column_exists?(:audit_logs, :ip_address)
    add_column :audit_logs, :user_agent, :text unless column_exists?(:audit_logs, :user_agent)

    unless index_exists?(:audit_logs, [ :user_id, :created_at ])
      add_index :audit_logs, [ :user_id, :created_at ]
    end
    unless index_exists?(:audit_logs, [ :action, :created_at ])
      add_index :audit_logs, [ :action, :created_at ]
    end
    unless index_exists?(:audit_logs, [ :auditable_type, :auditable_id, :created_at ], name: "idx_audit_logs_on_auditable_and_created_at")
      add_index :audit_logs, [ :auditable_type, :auditable_id, :created_at ],
        name: "idx_audit_logs_on_auditable_and_created_at"
    end
  end
end
