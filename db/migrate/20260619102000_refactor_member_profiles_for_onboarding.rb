class RefactorMemberProfilesForOnboarding < ActiveRecord::Migration[8.1]
  def up
    drop_table :emergency_contacts, if_exists: true

    if column_exists?(:member_profiles, :phone)
      remove_index :member_profiles, :phone if index_exists?(:member_profiles, :phone)
      rename_column :member_profiles, :phone, :mobile_number
    elsif !column_exists?(:member_profiles, :mobile_number)
      add_column :member_profiles, :mobile_number, :string
    end

    add_index :member_profiles, :mobile_number unless index_exists?(:member_profiles, :mobile_number)

    execute "UPDATE member_profiles SET gender = NULL WHERE gender NOT IN (0, 1)"
    execute "UPDATE member_profiles SET status = 1 WHERE status = 2"
  end

  def down
    remove_index :member_profiles, :mobile_number if index_exists?(:member_profiles, :mobile_number)

    if column_exists?(:member_profiles, :mobile_number)
      rename_column :member_profiles, :mobile_number, :phone
    elsif !column_exists?(:member_profiles, :phone)
      add_column :member_profiles, :phone, :string
    end

    add_index :member_profiles, :phone unless index_exists?(:member_profiles, :phone)

    create_table :emergency_contacts, if_not_exists: true do |t|
      t.references :member_profile, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.string :relationship
      t.string :phone, null: false
      t.string :address

      t.timestamps
    end
  end
end
