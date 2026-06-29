class RenameCallToOrderToWelcomeSpeech < ActiveRecord::Migration[8.1]
  def change
    rename_column :meeting_minutes, :call_to_order, :welcome_speech
  end
end
