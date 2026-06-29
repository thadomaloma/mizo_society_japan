class AddFamilyDetailsToMemberProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :member_profiles, :father_name, :string
    add_column :member_profiles, :mother_name, :string
    add_column :member_profiles, :family_status, :integer, null: false, default: 0
    add_column :member_profiles, :spouse_name, :string
    add_index :member_profiles, :family_status
  end
end
