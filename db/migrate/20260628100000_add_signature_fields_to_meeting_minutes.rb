class AddSignatureFieldsToMeetingMinutes < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_minutes, :chairman_signature_name, :string
    add_column :meeting_minutes, :chairman_signature_title, :string
    add_column :meeting_minutes, :secretary_signature_name, :string
    add_column :meeting_minutes, :secretary_signature_title, :string
  end
end
