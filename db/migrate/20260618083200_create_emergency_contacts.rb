class CreateEmergencyContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :emergency_contacts do |t|
      t.references :member_profile, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.string :relationship
      t.string :phone, null: false
      t.text :address

      t.timestamps
    end
  end
end
