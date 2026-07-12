module Reports
  class MembersReport
    def summary
      @summary ||= {
        total_members: User.member.count,
        total_profiles: profiles.count,
        active_members: profiles.active.count,
        inactive_members: profiles.where.not(status: :active).count,
        new_members_this_month: profiles.where(joined_on: Date.current.all_month).count,
        gender: gender_summary,
        registered_children: registered_children_count,
        under_18_members: profiles.where("date_of_birth > ?", 18.years.ago.to_date).count,
        by_prefecture: profiles.group(:prefecture).count,
        by_city: profiles.group(:city).count,
        family_status: family_status_summary(profiles),
        age_levels: age_level_summary(profiles),
        recent_members: profiles.latest.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        summary_rows: [
          [ "MSJ Member Report" ],
          [ "Generated On", Date.current.iso8601 ],
          [ "Total Member Profiles", summary[:total_profiles] ],
          [ "Active Members", summary[:active_members] ],
          [ "Inactive or Suspended", summary[:inactive_members] ],
          [ "Male", summary.dig(:gender, :male) ],
          [ "Female", summary.dig(:gender, :female) ],
          [ "Gender Not Recorded", summary.dig(:gender, :not_recorded) ],
          [ "Single", summary.dig(:family_status, :single) ],
          [ "Family", summary.dig(:family_status, :family) ],
          [ "Registered Children", summary[:registered_children] ],
          [ "Member Profiles Under 18", summary[:under_18_members] ]
        ],
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

    def profiles
      @profiles ||= MemberProfile.includes(:user)
    end

    def gender_summary
      counts = profiles.group(:gender).count

      {
        male: counts.fetch("male", counts.fetch(MemberProfile.genders[:male], 0)).to_i,
        female: counts.fetch("female", counts.fetch(MemberProfile.genders[:female], 0)).to_i,
        not_recorded: counts.fetch(nil, 0).to_i
      }
    end

    def registered_children_count
      FamilyMember
        .where(member_profile_id: profiles.select(:id))
        .where("LOWER(relationship) = ?", "child")
        .count
    end

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
