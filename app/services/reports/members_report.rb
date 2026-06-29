module Reports
  class MembersReport
    def summary
      {
        total_members: User.member.count,
        active_members: MemberProfile.active.count,
        inactive_members: MemberProfile.where.not(status: :active).count,
        new_members_this_month: MemberProfile.where(joined_on: Date.current.all_month).count,
        by_prefecture: MemberProfile.group(:prefecture).count,
        by_city: MemberProfile.group(:city).count,
        recent_members: MemberProfile.includes(:user).latest.limit(10)
      }
    end

    def to_csv
      ReportCsvExporter.call(
        headers: [ "Membership Number", "Name", "Email", "Mobile Number", "Status", "City", "Prefecture", "Joined On" ],
        rows: MemberProfile.includes(:user).latest.map do |profile|
          [
            profile.membership_number,
            profile.full_name,
            profile.user.email,
            profile.mobile_number,
            profile.status,
            profile.city,
            profile.prefecture,
            profile.joined_on
          ]
        end
      )
    end
  end
end
