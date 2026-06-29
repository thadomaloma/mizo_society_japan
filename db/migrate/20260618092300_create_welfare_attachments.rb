class CreateWelfareAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :welfare_attachments do |t|
      t.references :welfare_case, null: false, foreign_key: true
      t.bigint :uploaded_by_id, null: false

      t.timestamps
    end

    add_index :welfare_attachments, :uploaded_by_id
    add_foreign_key :welfare_attachments, :users, column: :uploaded_by_id
  end
end
