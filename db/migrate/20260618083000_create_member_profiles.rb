class CreateMemberProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :member_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :membership_number, null: false
      t.string :full_name, null: false
      t.string :phone
      t.integer :gender
      t.date :date_of_birth
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :prefecture
      t.string :postal_code
      t.date :joined_on
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :member_profiles, :membership_number, unique: true
    add_index :member_profiles, :full_name
    add_index :member_profiles, :phone
    add_index :member_profiles, :city
    add_index :member_profiles, :prefecture
    add_index :member_profiles, [ :status, :created_at ]
  end
end
