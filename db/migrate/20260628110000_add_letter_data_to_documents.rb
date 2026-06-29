class AddLetterDataToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :letter_data, :jsonb, null: false, default: {}
  end
end
