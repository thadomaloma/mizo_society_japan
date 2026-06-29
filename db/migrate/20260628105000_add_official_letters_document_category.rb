class AddOfficialLettersDocumentCategory < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO document_categories (name, description, active, position, created_at, updated_at)
      VALUES ('Official Letters', 'Formal outgoing letters and archived final copies.', TRUE, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT (name) DO UPDATE SET
        description = EXCLUDED.description,
        active = TRUE,
        updated_at = CURRENT_TIMESTAMP
    SQL
  end

  def down
    execute <<~SQL.squish
      DELETE FROM document_categories
      WHERE name = 'Official Letters'
        AND NOT EXISTS (SELECT 1 FROM documents WHERE documents.document_category_id = document_categories.id)
    SQL
  end
end
