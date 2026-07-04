module Reports
  class MembersReport
    def summary
      profiles = MemberProfile.includes(:user)

      {
        total_members: User.member.count,
        active_members: profiles.active.count,
        inactive_members: profiles.where.not(status: :active).count,
        new_members_this_month: profiles.where(joined_on: Date.current.all_month).count,
        by_prefecture: profiles.group(:prefecture).count,
        by_city: profiles.group(:city).count,
        family_status: family_status_summary(profiles),
        age_levels: age_level_summary(profiles),
        recent_members: profiles.latest.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        headers: [
          "Membership Number",
          "Full Name",
          "Email",
          "Mobile Number",
          "Gender",
          "Date of Birth",
          "Age",
          "Father's Name",
          "Mother's Name",
          "Family Status",
          "Spouse Name",
          "Children",
          "Status",
          "Postal Code",
          "Prefecture",
          "City",
          "Address Line 1",
          "Address Line 2",
          "Full Address",
          "Joined On"
        ],
        rows: MemberProfile.includes(:user, :family_members).latest.map do |profile|
          [
            profile.membership_number,
            profile.full_name,
            profile.user.email,
            profile.mobile_number,
            profile.gender,
            profile.date_of_birth,
            profile.age,
            profile.father_name,
            profile.mother_name,
            profile.family_status,
            profile.spouse_name,
            child_names(profile),
            profile.status,
            profile.postal_code,
            profile.prefecture,
            profile.city,
            profile.address_line1,
            profile.address_line2,
            profile.full_address,
            profile.joined_on
          ]
        end
      )
    end

    private

    AGE_LEVELS = [
      [ "Under 18", ..17 ],
      [ "18-29", 18..29 ],
      [ "30-39", 30..39 ],
      [ "40-49", 40..49 ],
      [ "50-59", 50..59 ],
      [ "60+", 60.. ],
      [ "Unknown", nil ]
    ].freeze

    def family_status_summary(profiles)
      counts = profiles.group(:family_status).count
      single = counts.fetch("single", counts.fetch(MemberProfile.family_statuses[:single], 0)).to_i
      family = counts.fetch("family", counts.fetch(MemberProfile.family_statuses[:family], 0)).to_i
      total = single + family

      {
        single: single,
        family: family,
        total: total,
        single_percentage: percentage(single, total),
        family_percentage: percentage(family, total)
      }
    end

    def age_level_summary(profiles)
      counts = AGE_LEVELS.to_h { |label, _range| [ label, 0 ] }

      profiles.find_each do |profile|
        age = profile.age
        label = AGE_LEVELS.find { |_name, range| range.nil? ? age.blank? : age.present? && range.cover?(age) }&.first
        counts[label || "Unknown"] += 1
      end

      total = counts.values.sum
      AGE_LEVELS.map do |label, _range|
        count = counts.fetch(label, 0)
        { label: label, count: count, percentage: percentage(count, total) }
      end
    end

    def percentage(value, total)
      return 0 unless total.to_i.positive?

      ((value.to_f / total) * 100).round
    end

    def child_names(profile)
      profile.child_family_members.map(&:name).compact_blank.join("; ")
    end
  end
end
