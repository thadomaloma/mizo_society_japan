class DashboardController < ApplicationController
  PREFECTURE_ROMAJI = {
    "北海道" => "Hokkaido",
    "青森県" => "Aomori",
    "岩手県" => "Iwate",
    "宮城県" => "Miyagi",
    "秋田県" => "Akita",
    "山形県" => "Yamagata",
    "福島県" => "Fukushima",
    "茨城県" => "Ibaraki",
    "栃木県" => "Tochigi",
    "群馬県" => "Gunma",
    "埼玉県" => "Saitama",
    "千葉県" => "Chiba",
    "東京都" => "Tokyo",
    "神奈川県" => "Kanagawa",
    "新潟県" => "Niigata",
    "富山県" => "Toyama",
    "石川県" => "Ishikawa",
    "福井県" => "Fukui",
    "山梨県" => "Yamanashi",
    "長野県" => "Nagano",
    "岐阜県" => "Gifu",
    "静岡県" => "Shizuoka",
    "愛知県" => "Aichi",
    "三重県" => "Mie",
    "滋賀県" => "Shiga",
    "京都府" => "Kyoto",
    "大阪府" => "Osaka",
    "兵庫県" => "Hyogo",
    "奈良県" => "Nara",
    "和歌山県" => "Wakayama",
    "鳥取県" => "Tottori",
    "島根県" => "Shimane",
    "岡山県" => "Okayama",
    "広島県" => "Hiroshima",
    "山口県" => "Yamaguchi",
    "徳島県" => "Tokushima",
    "香川県" => "Kagawa",
    "愛媛県" => "Ehime",
    "高知県" => "Kochi",
    "福岡県" => "Fukuoka",
    "佐賀県" => "Saga",
    "長崎県" => "Nagasaki",
    "熊本県" => "Kumamoto",
    "大分県" => "Oita",
    "宮崎県" => "Miyazaki",
    "鹿児島県" => "Kagoshima",
    "沖縄県" => "Okinawa"
  }.freeze

  def index
    authorize :dashboard, :show?

    @latest_payments = current_user.membership_payments.where(payment_batch_id: nil).includes(:membership_plan).latest.limit(3)
    @latest_payment_batches = current_user.payment_batches.where.not(status: :pending).includes(membership_payments: :membership_plan).latest.limit(2)
    @pending_payment_count = current_user.membership_payments.pending.count + current_user.payment_batches.pending_verification.count
    @unread_notification_count = current_user.notifications.unread.count
    @latest_notifications = current_user.notifications.latest.limit(4)
    @visible_announcement_count = Announcement.visible_to_members.count
    @latest_announcements = Announcement.visible_to_members.limit(3)
    @upcoming_events = EventPolicy::Scope.new(current_user, Event).resolve.upcoming.limit(3)
    @latest_documents = Document.visible_to(current_user)
      .includes(:document_category, file_attachment: :blob)
      .latest
      .limit(3)
    @latest_meeting_minutes = if current_user.minutes_access?
      MeetingMinute.visible_to(current_user).with_attached_file.latest.limit(3)
    else
      MeetingMinute.none
    end
    @my_open_welfare_cases = current_user.welfare_cases
      .includes(:welfare_category, :assigned_to)
      .open_cases
      .latest
      .limit(3)
    @recent_welfare_updates = current_user.welfare_cases
      .includes(:welfare_category)
      .latest
      .limit(3)
    @latest_pinned_announcement = Announcement.visible_to_members.pinned.first
    @profile_completion_percentage = helpers.profile_completion_percentage
    @show_events_dashboard = @upcoming_events.any?
    @show_welfare_dashboard = current_user.welfare_viewer? || @recent_welfare_updates.any?
    @community_overview = community_overview
    @member_stats = member_stats
    @recent_updates = recent_updates
    @dashboard_announcements = @latest_announcements.limit(3)

    @quick_links = [
      { label: "Updates", description: "Official notices and society updates", status: "#{@visible_announcement_count} available", path: events_path },
      { label: "Payments", description: "Membership dues and receipts", status: "#{@pending_payment_count} pending", path: membership_payments_path }
    ]
    @quick_links.insert(3, { label: "Welfare", description: "Confidential help requests and support updates", status: "#{@my_open_welfare_cases.count} open", path: welfare_cases_path }) if @show_welfare_dashboard
    if current_user.minutes_access?
      @quick_links.insert(3, { label: "Meeting Minutes", description: "Published minutes visible to your role", status: "#{@latest_meeting_minutes.count} available", path: meeting_minutes_path })
    end
  end

  private

  def community_overview
    prefecture_counts = MemberProfile.active
      .where.not(prefecture: [ nil, "" ])
      .group(:prefecture)
      .count
    current_prefecture = current_user.member_profile&.prefecture.to_s.strip.presence
    current_prefecture_count = current_prefecture ? prefecture_counts.fetch(current_prefecture, 0) : 0
    family_status_counts = MemberProfile.active.group(:family_status).count
    single_count = family_status_counts.fetch("single", family_status_counts.fetch(MemberProfile.family_statuses[:single], 0))
    family_count = family_status_counts.fetch("family", family_status_counts.fetch(MemberProfile.family_statuses[:family], 0))
    family_status_total = single_count + family_count

    {
      total_active_members: MemberProfile.active.count,
      current_prefecture: display_prefecture(current_prefecture),
      current_prefecture_count: community_count_label(current_prefecture_count),
      family_status_total: family_status_total,
      single_members: single_count,
      family_members: family_count,
      single_percentage: percentage_of(single_count, family_status_total),
      family_percentage: percentage_of(family_count, family_status_total),
      top_prefectures: prefecture_counts
        .select { |_prefecture, count| count >= 3 }
        .sort_by { |prefecture, count| [ -count, prefecture ] }
        .map { |prefecture, count| [ display_prefecture(prefecture), count ] }
        .first(5)
    }
  end

  def display_prefecture(prefecture)
    return if prefecture.blank?

    PREFECTURE_ROMAJI.fetch(prefecture.to_s.strip, prefecture)
  end

  def community_count_label(count)
    return "Not set" if count.zero?
    return "Few members" if count < 3

    count
  end

  def percentage_of(count, total)
    return 0 if total.to_i.zero?

    ((count.to_f / total) * 100).round
  end

  def member_stats
    stats = [
      { label: "Payments Due", value: @pending_payment_count, icon: :finance }
    ]
    stats << { label: "Announcements", value: @visible_announcement_count, icon: :announcements }
    stats << { label: "Upcoming Events", value: @upcoming_events.count, icon: :events }
    stats << if @show_welfare_dashboard
      { label: "My Welfare", value: @my_open_welfare_cases.count, icon: :welfare }
    else
      { label: "Profile", value: "#{@profile_completion_percentage}%", icon: :members }
    end
    stats
  end

  def recent_updates
    updates = @latest_announcements.limit(3).map do |announcement|
      { title: announcement.title, subtitle: announcement.published_at&.strftime("%b %d, %Y") || "Published", icon: :announcements, path: announcement_path(announcement) }
    end
    updates += current_user.notifications.latest.limit(3).map do |notification|
      { title: notification.title, subtitle: notification.created_at.strftime("%b %d, %Y"), icon: :notifications, path: notifications_path }
    end
    updates.first(3)
  end
end
