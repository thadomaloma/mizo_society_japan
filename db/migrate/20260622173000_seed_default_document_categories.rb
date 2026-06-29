class SeedDefaultDocumentCategories < ActiveRecord::Migration[8.1]
  DEFAULT_CATEGORIES = [
    [ "Forms", "Member forms and official applications." ],
    [ "Reports", "Society reports and official records." ],
    [ "Policies", "Policies, constitutions, and guidance." ],
    [ "Meeting Records", "Published meeting-related documents." ],
    [ "Finance", "Finance documents visible to authorised users." ]
  ].freeze

  def up
    DEFAULT_CATEGORIES.each_with_index do |(name, description), position|
      execute <<~SQL.squish
        INSERT INTO document_categories (name, description, active, position, created_at, updated_at)
        VALUES (#{connection.quote(name)}, #{connection.quote(description)}, TRUE, #{position}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (name) DO NOTHING
      SQL
    end
  end

  def down
    execute <<~SQL.squish
      DELETE FROM document_categories
      WHERE name IN ('Forms', 'Reports', 'Policies', 'Meeting Records', 'Finance')
        AND NOT EXISTS (SELECT 1 FROM documents WHERE documents.document_category_id = document_categories.id)
    SQL
  end
end
