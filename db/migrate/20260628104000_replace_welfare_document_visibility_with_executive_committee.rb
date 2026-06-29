class ReplaceWelfareDocumentVisibilityWithExecutiveCommittee < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE documents
      SET visibility = 2
      WHERE visibility = 4
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Legacy welfare-only document visibility was converted to Office Bearers Only."
  end
end
