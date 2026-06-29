class CreateEventCategoriesAndReplaceEventType < ActiveRecord::Migration[8.1]
  DEFAULT_CATEGORIES = {
    "general" => "General",
    "meeting" => "Meeting",
    "sports" => "Sports",
    "cultural" => "Cultural",
    "welfare" => "Welfare",
    "youth" => "Youth",
    "women" => "Women",
    "kids" => "Kids",
    "religious" => "Religious",
    "fundraising" => "Fundraising"
  }.freeze

  def up
    create_table :event_categories do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_categories, :name, unique: true
    add_index :event_categories, :active
    add_index :event_categories, :position

    DEFAULT_CATEGORIES.each_with_index do |(_code, name), position|
      execute <<~SQL.squish
        INSERT INTO event_categories (name, active, position, created_at, updated_at)
        VALUES (#{connection.quote(name)}, TRUE, #{position}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    add_reference :events, :event_category, foreign_key: true

    execute <<~SQL.squish
      UPDATE events
      SET event_category_id = event_categories.id
      FROM event_categories
      WHERE event_categories.name = CASE events.event_type
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'Meeting'
        WHEN 2 THEN 'Sports'
        WHEN 3 THEN 'Cultural'
        WHEN 4 THEN 'Welfare'
        WHEN 5 THEN 'Youth'
        WHEN 6 THEN 'Women'
        WHEN 7 THEN 'Kids'
        WHEN 8 THEN 'Religious'
        ELSE 'Fundraising'
      END
    SQL

    change_column_null :events, :event_category_id, false
    remove_index :events, :event_type
    remove_column :events, :event_type
  end

  def down
    add_column :events, :event_type, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE events
      SET event_type = CASE event_categories.name
        WHEN 'General' THEN 0
        WHEN 'Meeting' THEN 1
        WHEN 'Sports' THEN 2
        WHEN 'Cultural' THEN 3
        WHEN 'Welfare' THEN 4
        WHEN 'Youth' THEN 5
        WHEN 'Women' THEN 6
        WHEN 'Kids' THEN 7
        WHEN 'Religious' THEN 8
        ELSE 9
      END
      FROM event_categories
      WHERE events.event_category_id = event_categories.id
    SQL

    add_index :events, :event_type
    remove_reference :events, :event_category, foreign_key: true
    drop_table :event_categories
  end
end
