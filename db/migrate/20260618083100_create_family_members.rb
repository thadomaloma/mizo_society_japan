class CreateFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :family_members do |t|
      t.references :member_profile, null: false, foreign_key: true
      t.string :name, null: false
      t.string :relationship, null: false
      t.date :date_of_birth
      t.string :phone
      t.text :notes

      t.timestamps
    end
  end
end
