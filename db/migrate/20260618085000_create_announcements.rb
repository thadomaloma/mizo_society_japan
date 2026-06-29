class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.integer :category, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.boolean :pinned, null: false, default: false
      t.datetime :published_at
      t.bigint :author_id, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :announcements, :author_id
    add_index :announcements, :category
    add_index :announcements, :status
    add_index :announcements, :pinned
    add_index :announcements, :published_at
    add_index :announcements, :expires_at
    add_index :announcements, [ :status, :pinned, :published_at ], name: "idx_announcements_on_status_pinned_published"
    add_foreign_key :announcements, :users, column: :author_id
  end
end
