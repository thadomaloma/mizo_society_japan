module Reports
  class MembersReport
    AGE_FILTER_OPTIONS = [
      [ "All ages", "" ],
      [ "Under 18", "under_18" ],
      [ "18-29", "18_29" ],
      [ "30-39", "30_39" ],
      [ "40-49", "40_49" ],
      [ "50-59", "50_59" ],
      [ "60+", "60_plus" ],
      [ "Age not recorded", "unknown" ]
    ].freeze

    AGE_LEVELS = [
      [ "Under 18", ..17 ],
      [ "18-29", 18..29 ],
      [ "30-39", 30..39 ],
      [ "40-49", 40..49 ],
      [ "50-59", 50..59 ],
      [ "60+", 60.. ],
      [ "Unknown", nil ]
    ].freeze

    def summary
      @summary ||= {
        total_members: profiles.size,
        total_profiles: profiles.size,
        portal_accounts: User.count,
        active_members: profiles.count(&:active?),
        inactive_members: profiles.count { |profile| !profile.active? },
        new_members_this_month: profiles.count { |profile| profile.joined_on&.in?(Date.current.all_month) },
        gender: gender_summary,
        registered_children: children.size,
        registered_spouses: spouses.size,
        household_population: profiles.size + children.size + spouses.size,
        children_14_and_over: children.count { |child| child.age.to_i >= 14 },
        under_18_members: profiles.count { |profile| profile.age.present? && profile.age < 18 },
        by_prefecture: location_summary(:prefecture),
        by_city: location_summary(:city),
        family_status: family_status_summary,
        age_levels: age_level_summary,
        data_quality: data_quality_summary,
        recent_members: directory_profiles.first(10)
      }
    end

    def directory_profiles
      @directory_profiles ||= profiles.sort_by do |profile|
        [ profile.full_name.to_s.downcase, profile.membership_number.to_s ]
      end
    end

    def directory_scope(filters: {})
      scope = MemberProfile.left_joins(:user).includes(:user, :family_members)
      scope = filter_by_query(scope, filters[:query])
      scope = scope.where(status: filters[:status]) if MemberProfile.statuses.key?(filters[:status].to_s)
      scope = scope.where(family_status: filters[:family_status]) if MemberProfile.family_statuses.key?(filters[:family_status].to_s)
      scope = scope.where(prefecture: filters[:prefecture]) if filters[:prefecture].present?
      scope = filter_by_age(scope, filters[:age_group])
      scope.order(Arel.sql("LOWER(member_profiles.full_name) ASC"), :membership_number)
    end

    def prefecture_options
      MemberProfile.where.not(prefecture: [ nil, "" ]).distinct.order(:prefecture).pluck(:prefecture)
    end

    def to_csv
      ReportCsvExporter.call(
        bom: true,
        headers: csv_headers,
        rows: directory_profiles.map { |profile| csv_profile_row(profile) }
      )
    end

    private

    def filter_by_query(scope, query)
      normalized_query = query.to_s.strip
      return scope if normalized_query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized_query)}%"
      scope.where(
        <<~SQL.squish,
          member_profiles.full_name ILIKE :query
          OR member_profiles.membership_number ILIKE :query
          OR member_profiles.mobile_number ILIKE :query
          OR member_profiles.city ILIKE :query
          OR member_profiles.prefecture ILIKE :query
          OR users.email ILIKE :query
        SQL
        query: pattern
      )
    end

    def filter_by_age(scope, age_group)
      case age_group.to_s
      when "under_18"
        scope.where("member_profiles.date_of_birth > ?", 18.years.ago.to_date)
      when "18_29"
        scope.where(member_profiles: { date_of_birth: 30.years.ago.to_date.next_day..18.years.ago.to_date })
      when "30_39"
        scope.where(member_profiles: { date_of_birth: 40.years.ago.to_date.next_day..30.years.ago.to_date })
      when "40_49"
        scope.where(member_profiles: { date_of_birth: 50.years.ago.to_date.next_day..40.years.ago.to_date })
      when "50_59"
        scope.where(member_profiles: { date_of_birth: 60.years.ago.to_date.next_day..50.years.ago.to_date })
      when "60_plus"
        scope.where("member_profiles.date_of_birth <= ?", 60.years.ago.to_date)
      when "unknown"
        scope.where(date_of_birth: nil)
      else
        scope
      end
    end

    def profiles
      @profiles ||= MemberProfile.includes(:user, :family_members).to_a
    end

    def children
      @children ||= profiles.flat_map { |profile| profile.family_members.select(&:child?) }
    end

    def spouses
      @spouses ||= profiles.flat_map { |profile| profile.family_members.select(&:spouse?) }
    end

    def gender_summary
      counts = profiles.group_by { |profile| profile.gender.presence || "not_recorded" }.transform_values(&:size)

      {
        male: counts.fetch("male", 0),
        female: counts.fetch("female", 0),
        not_recorded: counts.fetch("not_recorded", 0)
      }
    end

    def family_status_summary
      counts = profiles.group_by { |profile| profile.family_status.presence || "not_recorded" }.transform_values(&:size)
      single = counts.fetch("single", 0)
      family = counts.fetch("family", 0)
      not_recorded = counts.fetch("not_recorded", 0)
      total = single + family + not_recorded

      {
        single: single,
        family: family,
        not_recorded: not_recorded,
        total: total,
        single_percentage: percentage(single, total),
        family_percentage: percentage(family, total)
      }
    end

    def age_level_summary
      counts = AGE_LEVELS.to_h { |label, _range| [ label, 0 ] }

      profiles.each do |profile|
        age = profile.age
        label = AGE_LEVELS.find { |_name, range| range.nil? ? age.blank? : age.present? && range.cover?(age) }&.first
        counts[label || "Unknown"] += 1
      end

      AGE_LEVELS.map do |label, _range|
        count = counts.fetch(label, 0)
        { label: label, count: count, percentage: percentage(count, profiles.size) }
      end
    end

    def location_summary(attribute)
      profiles
        .group_by do |profile|
          value = profile.public_send(attribute)
          attribute == :prefecture ? (JapanPrefecture.romaji(value) || "Not recorded") : (value.presence || "Not recorded")
        end
        .transform_values(&:size)
        .sort_by { |name, count| [ -count, name.to_s ] }
        .to_h
    end

    def data_quality_summary
      total = profiles.size
      fields = {
        gender_recorded: profiles.count { |profile| profile.gender.present? },
        date_of_birth_recorded: profiles.count { |profile| profile.date_of_birth.present? },
        mobile_recorded: profiles.count { |profile| profile.mobile_number.present? },
        address_complete: profiles.count { |profile| profile.full_address.present? }
      }

      fields.merge(
        complete_profiles: profiles.count(&:complete?),
        completion_percentage: percentage(profiles.count(&:complete?), total)
      )
    end

    def percentage(value, total)
      return 0 unless total.to_i.positive?

      ((value.to_f / total) * 100).round
    end

    def csv_headers
      [
        "Membership Number", "Full Name", "Account Role", "Member Status", "Joined Date",
        "Mobile Number", "Email Address", "Gender", "Date of Birth", "Age", "Family Status",
        "Spouse Name", "Children Count", "Children Details", "Household Size", "Father's Name",
        "Mother's Name", "Full Address", "Profile Completion (%)"
      ]
    end

    def csv_profile_row(profile)
      [
        profile.membership_number,
        profile.full_name,
        profile.user&.role&.humanize,
        profile.status&.humanize,
        profile.joined_on&.iso8601,
        profile.mobile_number,
        profile.user&.email,
        profile.gender&.humanize,
        profile.date_of_birth&.iso8601,
        profile.age,
        profile.family_status&.humanize,
        profile.spouse_name,
        profile.family_members.count(&:child?),
        child_details(profile),
        1 + profile.family_members.size,
        profile.father_name,
        profile.mother_name,
        profile.full_address,
        profile.profile_completion_percentage
      ]
    end

    def child_details(profile)
      profile.family_members.select(&:child?).map do |child|
        [
          child.name,
          "DOB: #{child.date_of_birth&.iso8601 || 'Not recorded'}",
          "Age: #{child.age || 'Not recorded'}"
        ].join(" | ")
      end.join("\n")
    end
  end
end
