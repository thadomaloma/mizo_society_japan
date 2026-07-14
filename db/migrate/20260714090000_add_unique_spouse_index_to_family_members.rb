class AddUniqueSpouseIndexToFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    add_index :family_members,
      :member_profile_id,
      unique: true,
      where: "LOWER(relationship) = 'spouse'",
      name: "index_family_members_on_unique_spouse"
  end
end
