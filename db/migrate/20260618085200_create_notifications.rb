class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint :recipient_id, null: false
      t.bigint :actor_id
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.integer :action, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, :recipient_id
    add_index :notifications, :actor_id
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
    add_index :notifications, [ :recipient_id, :read_at ]
    add_index :notifications, [ :recipient_id, :action, :notifiable_type, :notifiable_id ], unique: true, name: "idx_notifications_unique_recipient_action_notifiable"
    add_foreign_key :notifications, :users, column: :recipient_id
    add_foreign_key :notifications, :users, column: :actor_id
  end
end
