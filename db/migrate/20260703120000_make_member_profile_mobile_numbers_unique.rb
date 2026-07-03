class MakeMemberProfileMobileNumbersUnique < ActiveRecord::Migration[8.1]
  def up
    normalize_existing_mobile_numbers
    clear_duplicate_mobile_numbers

    remove_index :member_profiles, :mobile_number if index_exists?(:member_profiles, :mobile_number)
    add_index :member_profiles, :mobile_number, unique: true, where: "mobile_number IS NOT NULL AND mobile_number <> ''"
  end

  def down
    remove_index :member_profiles, :mobile_number if index_exists?(:member_profiles, :mobile_number)
    add_index :member_profiles, :mobile_number unless index_exists?(:member_profiles, :mobile_number)
  end

  private

  def normalize_existing_mobile_numbers
    say_with_time "Normalizing member profile mobile numbers" do
      select_all("SELECT id, mobile_number FROM member_profiles WHERE mobile_number IS NOT NULL AND mobile_number <> ''").each do |row|
        normalized = normalize_mobile_number(row["mobile_number"])
        execute sanitize_sql([ "UPDATE member_profiles SET mobile_number = ? WHERE id = ?", normalized, row["id"] ])
      end
    end
  end

  def clear_duplicate_mobile_numbers
    say_with_time "Clearing duplicate member profile mobile numbers" do
      duplicate_rows = select_all(<<~SQL.squish)
        SELECT id
        FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY mobile_number
                   ORDER BY updated_at DESC NULLS LAST, id ASC
                 ) AS duplicate_rank
          FROM member_profiles
          WHERE mobile_number IS NOT NULL AND mobile_number <> ''
        ) ranked_profiles
        WHERE duplicate_rank > 1
      SQL

      duplicate_rows.each do |row|
        execute sanitize_sql([ "UPDATE member_profiles SET mobile_number = NULL WHERE id = ?", row["id"] ])
      end
    end
  end

  def normalize_mobile_number(value)
    normalized = value.to_s
      .tr("０１２３４５６７８９", "0123456789")
      .strip
      .gsub(/[[:space:]\-ー−()（）]/, "")

    if normalized.start_with?("+81")
      "0#{normalized.delete_prefix('+81').gsub(/\D/, '')}"
    else
      normalized.gsub(/\D/, "")
    end
  end

  def sanitize_sql(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
