module ApplicationHelper
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

  ICONS = {
    dashboard: "M3 11.5 12 4l9 7.5V21a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z",
    home: "M3 11.5 12 4l9 7.5V21a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1v-9.5Z",
    members: "M8 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8Zm8.5 1a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7ZM2 21a6 6 0 0 1 12 0H2Zm12.5 0a7.5 7.5 0 0 0-2-5.1A5.5 5.5 0 0 1 22 19.5V21h-7.5Z",
    finance: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 5v1.2a3 3 0 0 1 2.2 1.4l-1.6.9A1.5 1.5 0 0 0 12.2 10h-.5c-.8 0-1.2.3-1.2.8 0 .6.5.8 1.8 1.1 1.8.4 3.2 1 3.2 2.8 0 1.5-1 2.5-2.5 2.9V19h-2v-1.3a3.6 3.6 0 0 1-2.8-1.8l1.7-1a2 2 0 0 0 1.9 1h.4c.9 0 1.3-.4 1.3-.9 0-.6-.5-.8-1.9-1.1-1.7-.4-3.1-1-3.1-2.8 0-1.4 1-2.5 2.5-2.8V7h2Z",
    welfare: "M12 21s-8-4.8-8-12a5 5 0 0 1 8-4 5 5 0 0 1 8 4c0 7.2-8 12-8 12Zm-1-6h2v-3h3v-2h-3V7h-2v3H8v2h3v3Z",
    events: "M7 2h2v3h6V2h2v3h3a1 1 0 0 1 1 1v15a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h3V2Zm12 8H5v10h14V10Z",
    announcements: "M4 10v4h3l7 4V6l-7 4H4Zm13-3.5a6 6 0 0 1 0 11l-.8-1.8a4 4 0 0 0 0-7.4l.8-1.8Z",
    documents: "M6 2h8l5 5v15H6a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Zm7 1.5V8h4.5L13 3.5ZM8 12h8v2H8v-2Zm0 4h8v2H8v-2Z",
    reports: "M4 21V4h16v17H4Zm3-3h2v-6H7v6Zm4 0h2V8h-2v10Zm4 0h2v-4h-2v4Z",
    printer: "M7 3h10v4H7V3Zm10 14v4H7v-4h10Zm2-8a3 3 0 0 1 3 3v5h-3v-2H5v2H2v-5a3 3 0 0 1 3-3h14Zm0 3a1 1 0 1 0 0 2 1 1 0 0 0 0-2Z",
    tag: "M12.6 2.6a2 2 0 0 0-2.8 0l-6.4 6.4a2 2 0 0 0 0 2.8l8.8 8.8a2 2 0 0 0 2.8 0l6.4-6.4a2 2 0 0 0 0-2.8l-8.8-8.8ZM14 9a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3Z",
    settings: "M19.4 13.5a7.8 7.8 0 0 0 0-3l2-1.5-2-3.5-2.4 1a8 8 0 0 0-2.6-1.5L14 2h-4l-.4 3a8 8 0 0 0-2.6 1.5l-2.4-1-2 3.5 2 1.5a7.8 7.8 0 0 0 0 3l-2 1.5 2 3.5 2.4-1a8 8 0 0 0 2.6 1.5l.4 3h4l.4-3a8 8 0 0 0 2.6-1.5l2.4 1 2-3.5-2-1.5ZM12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7Z",
    notifications: "M18 16v-5a6 6 0 1 0-12 0v5l-2 2v1h16v-1l-2-2ZM9.5 21h5a2.5 2.5 0 0 1-5 0Z",
    moon: "M21 13.8A8.6 8.6 0 0 1 10.2 3a9.5 9.5 0 1 0 10.8 10.8Z",
    sun: "M12 7a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0-5 1.4 3h-2.8L12 2Zm0 17 1.4 3h-2.8l1.4-3ZM4.2 4.2l3.1 1.1-2 2-1.1-3.1Zm14.5 12.5 3.1 1.1-1.1-3.1-2 2ZM2 12l3-1.4v2.8L2 12Zm17 0 3-1.4v2.8L19 12ZM4.2 19.8l1.1-3.1 2 2-3.1 1.1ZM18.7 7.3l2-2 1.1 3.1-3.1-1.1Z",
    chevron_down: "m7 9 5 5 5-5H7Z",
    logout: "M4 3h9v2H6v14h7v2H4V3Zm11.5 5.5L17 7l5 5-5 5-1.5-1.5L18 13h-7v-2h7l-2.5-2.5Z",
    search: "M10.5 3a7.5 7.5 0 0 1 5.9 12.1l4.2 4.3-1.4 1.4-4.3-4.2A7.5 7.5 0 1 1 10.5 3Zm0 2a5.5 5.5 0 1 0 0 11 5.5 5.5 0 0 0 0-11Z",
    more: "M5 12a2 2 0 1 1 0 .01V12Zm7 0a2 2 0 1 1 0 .01V12Zm7 0a2 2 0 1 1 0 .01V12Z",
    plus: "M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6V5Z",
    clock: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 5v5.6l3.5 2.1-1 1.7L11 13.7V7h2Z",
    shield_check: "M12 2 20 5.5v6.2c0 4.5-3.1 8.7-8 10.3-4.9-1.6-8-5.8-8-10.3V5.5L12 2Zm3.6 7.2-4.5 4.5-2-2-1.4 1.4 3.4 3.4L17 10.6l-1.4-1.4Z",
    banknotes: "M4 6h16a2 2 0 0 1 2 2v9H6a2 2 0 0 1-2-2V6Zm2 2v7h14V8H6Zm6 1.5a2 2 0 1 1 0 4 2 2 0 0 1 0-4ZM2 9h2v8h14v2H4a2 2 0 0 1-2-2V9Z",
    arrow_path: "M12 4a8 8 0 0 1 7.4 5H22l-3.8 4L14.4 9H17a6 6 0 0 0-10.7-1.7L4.8 6A8 8 0 0 1 12 4Zm-7.4 11H2l3.8-4 3.8 4H7a6 6 0 0 0 10.7 1.7l1.5 1.3A8 8 0 0 1 4.6 15Z",
    pencil_square: "M5 3h10v2H5v14h14V9h2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm13.8-.2 2.4 2.4-8.7 8.7H10v-2.5l8.8-8.6Z",
    eye: "M12 5c5 0 8.8 4.4 10 7-1.2 2.6-5 7-10 7S3.2 14.6 2 12c1.2-2.6 5-7 10-7Zm0 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0 2a2 2 0 1 1 0 4 2 2 0 0 1 0-4Z",
    eye_slash: "M3.3 2 22 20.7 20.7 22l-4-4A11.4 11.4 0 0 1 12 19c-5 0-8.8-4.4-10-7 .6-1.3 1.9-3.1 3.7-4.5L2 3.3 3.3 2Zm4 7.3A8.9 8.9 0 0 0 4.2 12c1 1.8 4 5 7.8 5 1.1 0 2.2-.3 3.2-.8l-1.7-1.7a4 4 0 0 1-5-5L7.3 9.3ZM12 5c5 0 8.8 4.4 10 7a13.2 13.2 0 0 1-2.6 3.7l-2.1-2.1c.3-.5.4-1 .4-1.6a4 4 0 0 0-5.3-3.8L10.7 6.5c.4-.1.9-.1 1.3-.1V5Z",
    edit: "M4 17.3V21h3.7L18.5 10.2l-3.7-3.7L4 17.3ZM20.7 8a1 1 0 0 0 0-1.4l-3.3-3.3a1 1 0 0 0-1.4 0l-1.8 1.8 3.7 3.7L20.7 8Z",
    filter: "M3 5h18v2l-7 7v5l-4 2v-7L3 7V5Z",
    check: "M9.2 16.6 4.9 12.3l-1.4 1.4 5.7 5.7L21 7.6l-1.4-1.4L9.2 16.6Z",
    x_mark: "m6.4 5 12.6 12.6-1.4 1.4L5 6.4 6.4 5Zm12.6 1.4L6.4 19 5 17.6 17.6 5 19 6.4Z",
    trash: "M9 3h6l1 2h5v2H3V5h5l1-2Zm-3 6h12l-.8 12H6.8L6 9Zm4 2v8h2v-8h-2Zm4 0v8h2v-8h-2Z",
    save: "M5 3h12l2 2v16H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm2 2v5h8V5H7Zm0 10v4h10v-4H7Z",
    arrow_left: "M10.8 5.4 4.2 12l6.6 6.6 1.4-1.4L8 13h12v-2H8l4.2-4.2-1.4-1.4Z",
    paperclip: "M8.5 18.5a5 5 0 0 1 0-7.1l6.3-6.3a3.5 3.5 0 1 1 5 5l-7.1 7.1a2 2 0 1 1-2.8-2.8l6.7-6.7 1.4 1.4-6.7 6.7 0 0a.1.1 0 0 0 .1.1l7.1-7.1a1.5 1.5 0 0 0-2.1-2.1l-6.3 6.3a3 3 0 1 0 4.2 4.2l5.7-5.7 1.4 1.4-5.7 5.7a5 5 0 0 1-7.2 0Z",
    upload: "M11 16V7.8L7.7 11 6.3 9.6 12 4l5.7 5.6-1.4 1.4L13 7.8V16h-2Zm-6 3h14v-4h2v6H3v-6h2v4Z",
    lock: "M7 10V8a5 5 0 0 1 10 0v2h1a2 2 0 0 1 2 2v8H4v-8a2 2 0 0 1 2-2h1Zm2 0h6V8a3 3 0 0 0-6 0v2Z",
    user_plus: "M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm0 2c-3.9 0-7 2.2-7 5v1h9.4A6.5 6.5 0 0 1 16 13.5c-1.6-.4-3.7-.5-7-.5Zm10 1v3h3v2h-3v3h-2v-3h-3v-2h3v-3h2Z",
    download: "M11 3h2v9l3.5-3.5 1.4 1.4L12 15.8 6.1 9.9l1.4-1.4L11 12V3Zm-6 14h2v2h10v-2h2v4H5v-4Z",
    copy: "M8 7a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2h-9a2 2 0 0 1-2-2V7Zm2 0v11h9V7h-9ZM3 6a3 3 0 0 1 3-3h9v2H6a1 1 0 0 0-1 1v11H3V6Z",
    credit_card: "M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6Zm2 2h14V6H5v2Zm0 3v7h14v-7H5Zm2 4h5v2H7v-2Z",
    arrow_right: "M13.2 5.4 19.8 12l-6.6 6.6-1.4-1.4L16 13H4v-2h12l-4.2-4.2 1.4-1.4Z",
    phone: "M6.6 2.5 10 5.9 8 8a13.2 13.2 0 0 0 8 8l2.1-2 3.4 3.3-1.7 1.8c-.9.9-2.2 1.2-3.4.9A19.2 19.2 0 0 1 4 7.6c-.3-1.2 0-2.5.9-3.4l1.7-1.7Z",
    chat: "M4 4h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H9l-5 4v-4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Zm3 5h10V7H7v2Zm0 4h7v-2H7v2Z"
  }.freeze

  def role_label(role)
    User.role_label(role)
  end

  def portal_organization_name
    AppSetting.get("organization_name", "Mizo Society of Japan")
  end

  def portal_notice
    AppSetting.get("portal_notice").to_s.strip.presence
  end

  def dashboard_home_path(user = current_user)
    admin_portal_user?(user) ? admin_dashboard_path : root_path
  end

  def portal_nav_items
    items = [
      { label: "Dashboard", path: dashboard_home_path, short: "Home", icon: :dashboard },
      { label: "Payments", path: membership_payments_path, short: "Finance", icon: :credit_card },
      { label: "AI Assistant", path: ai_assistant_path, short: "AI", icon: :chat },
      { label: "Welfare", path: welfare_cases_path, short: "Welfare", icon: :welfare },
      { label: "Events", path: events_path, short: "Events", icon: :events },
      { label: "Profile", path: profile_path, short: "Profile", icon: :members }
    ]

    if current_user&.minutes_access?
      items.insert(2, { label: "Minutes", path: meeting_minutes_path, short: "Minutes", icon: :documents })
    end
    items.insert(-2, { label: "Reports", path: admin_reports_path, short: "Reports", icon: :reports }) if current_user&.report_viewer? && !admin_portal_user?

    items
  end

  def admin_nav_items
    items = [
      { label: "Dashboard", path: admin_dashboard_path, icon: :dashboard, roles: :operations },
      { label: "AI Assistant", path: ai_assistant_path, icon: :chat },
      { label: "Payments", path: membership_payments_path, icon: :credit_card },
      { label: "Payment Records", path: admin_membership_payments_path, icon: :credit_card, roles: :finance },
      { label: "Payment Plans", path: admin_membership_plans_path, icon: :tag, roles: :finance },
      { label: "Transactions", path: admin_finance_transactions_path, icon: :finance, roles: :finance },
      { label: "Welfare", path: admin_welfare_cases_path, icon: :welfare, roles: :welfare },
      { label: "Minutes", path: meeting_minutes_path, icon: :documents, roles: :minutes },
      { label: "Events", path: events_path, icon: :events, roles: :events },
      { label: "Letters", path: documents_path, icon: :documents, roles: :content },
      { label: "Reports", path: admin_reports_path, icon: :reports, roles: :reports },
      { label: "Settings", path: admin_settings_path, icon: :settings, roles: :settings }
    ]

    items
  end

  def admin_portal_user?(user = current_user)
    user&.operations_team?
  end

  def nav_item_visible?(item, user = current_user)
    return user&.super_admin? if item[:roles] == :settings
    return true if admin_portal_user?(user)

    case item[:roles]
    when :admin then user&.super_admin?
    when :finance then user&.finance_viewer?
    when :welfare then user&.welfare_viewer?
    when :events then user&.event_manager?
    when :content then user&.event_manager?
    when :minutes then user&.minutes_access?
    when :reports then user&.report_viewer?
    when :settings then user&.super_admin?
    when :operations then user&.operations_team?
    else true
    end
  end

  def nav_active?(item)
    return controller_name.in?(%w[events announcements]) if item[:path] == events_path && item[:label] == "Events"
    return controller_name == "meeting_minutes" if item[:label] == "Minutes"
    return controller_name == "documents" if item[:label] == "Documents"
    return controller_name == "documents" if item[:label] == "Letters"

    item[:path] != "#" && current_page?(item[:path])
  rescue ActionController::UrlGenerationError
    false
  end

  def payment_nav_active?(item)
    case item[:label]
    when "Payments"
      controller_path.in?(%w[membership_payments payment_batches])
    when "Payment Records"
      controller_path.in?(%w[admin/membership_payments admin/payment_batches])
    when "Payment Plans"
      controller_path == "admin/membership_plans"
    else
      nav_active?(item)
    end
  end

  def visible_documents_available?(user = current_user)
    user.present? && Document.visible_to(user).exists?
  end

  def settings_section_active?
    [ admin_settings_path, admin_user_roles_path, admin_audit_logs_path, admin_permissions_path ].any? do |path|
      current_page?(path)
    end
  rescue ActionController::UrlGenerationError
    false
  end

  def icon_svg(name, classes: "h-5 w-5")
    path = ICONS.fetch(name.to_sym, ICONS[:dashboard])
    tag.svg(class: classes, viewBox: "0 0 24 24", fill: "currentColor", aria: { hidden: true }) do
      tag.path(d: path)
    end
  end

  def action_button_classes(variant = :primary, size: :sm, full_width: false, extra: nil)
    ::RubyUI::Button.new(
      variant: variant,
      size: size,
      full_width: full_width,
      class: extra
    ).attrs[:class]
  end

  def action_link(label, path, icon: :arrow_right, variant: :ghost, size: :xs, **options)
    html_options = options.merge(class: [ action_button_classes(variant, size: size), options[:class] ].compact.join(" "))

    link_to path, html_options do
      safe_join([ icon_svg(icon, classes: "h-3.5 w-3.5"), tag.span(label) ])
    end
  end

  def stat_card_classes(tone)
    {
      "red" => "bg-red-600 text-white",
      "dark" => "bg-[#0F172A] text-white dark:bg-[#334155]",
      "green" => "bg-emerald-600 text-white",
      "amber" => "bg-amber-500 text-white",
      "blue" => "bg-sky-600 text-white",
      "purple" => "bg-fuchsia-600 text-white"
    }.fetch(tone.to_s, "bg-[#0F172A] text-white dark:bg-[#334155]")
  end

  def yen(amount)
    number_to_currency(amount || 0, unit: "¥", precision: 0)
  end

  def prefecture_romaji(prefecture)
    value = prefecture.to_s.strip
    return if value.blank?

    PREFECTURE_ROMAJI.fetch(value, value)
  end

  def yen_input_value(amount)
    return nil if amount.blank?

    decimal = BigDecimal(amount.to_s)
    decimal.frac.zero? ? decimal.to_i : amount
  rescue ArgumentError
    amount
  end

  def user_label(user)
    profile = user.member_profile
    return "#{profile.full_name} (#{profile.membership_number})" if profile.present?

    user.display_name
  end

  def status_badge_classes(status)
    {
      "pending" => "bg-amber-50 text-amber-700 ring-amber-200",
      "pending_verification" => "bg-amber-50 text-amber-700 ring-amber-200",
      "paid" => "bg-sky-50 text-sky-700 ring-sky-200",
      "failed" => "bg-red-50 text-red-700 ring-red-200",
      "expired" => "bg-gray-100 text-gray-700 ring-gray-200",
      "cancelled" => "bg-red-50 text-red-700 ring-red-200",
      "refunded" => "bg-fuchsia-50 text-fuchsia-700 ring-fuchsia-200",
      "approved" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "rejected" => "bg-red-50 text-red-700 ring-red-200",
      "active" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "inactive" => "bg-gray-100 text-gray-700 ring-gray-200",
      "suspended" => "bg-red-50 text-red-700 ring-red-200",
      "income" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "expense" => "bg-red-50 text-red-700 ring-red-200",
      "draft" => "bg-gray-100 text-gray-700 ring-gray-200",
      "published" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "archived" => "bg-gray-200 text-gray-800 ring-gray-300",
      "pending_review" => "bg-amber-50 text-amber-700 ring-amber-200",
      "submitted" => "bg-amber-50 text-amber-700 ring-amber-200",
      "reviewing" => "bg-sky-50 text-sky-700 ring-sky-200",
      "in_progress" => "bg-indigo-50 text-indigo-700 ring-indigo-200",
      "resolved" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
      "completed" => "bg-sky-50 text-sky-700 ring-sky-200"
    }.fetch(status.to_s, "bg-gray-100 text-gray-700 ring-gray-200")
  end

  def status_badge_label(status, compact: false)
    return status.to_s.humanize unless compact

    {
      "pending_verification" => "To verify",
      "pending_review" => "Review",
      "requires_action" => "Action",
      "in_progress" => "Active"
    }.fetch(status.to_s, status.to_s.humanize)
  end

  def payment_review_label(payment)
    return "Ready to Verify" if payment.pending_verification?
    return "Waiting Transfer" if payment.pending?
    return "Paid" if payment.paid?

    payment.status.humanize
  end

  def payment_review_description(payment)
    return "Member submitted transfer details. Check the bank account, then approve or reject." if payment.pending_verification?
    return "Member has not submitted transfer details yet. Nothing to approve." if payment.pending?
    return "Approved and marked as paid." if payment.paid?

    payment.status.humanize
  end

  def payment_review_badge_classes(payment)
    return "bg-emerald-50 text-emerald-700 ring-emerald-200" if payment.paid?
    return "bg-amber-50 text-amber-700 ring-amber-200" if payment.pending_verification?
    return "bg-slate-100 text-slate-700 ring-slate-200" if payment.pending?

    status_badge_classes(payment.status)
  end

  def visibility_label(visibility)
    {
      "all_members" => "All Members",
      "public_access" => "Public Access",
      "members_only" => "Members Only",
      "executive_committee" => "Executive Committee",
      "executive_committee_only" => "Executive Committee Only",
      "office_bearers_only" => "Office Bearers Only",
      "finance_only" => "Finance Team Only",
      "finance_team_only" => "Finance Team Only",
      "welfare_team_only" => "Welfare Team Only"
    }.fetch(visibility.to_s, visibility.to_s.humanize)
  end

  def meeting_minute_attendance_badge(minute)
    "Present #{minute.present_count} · Absent #{minute.absent_count}"
  end

  def minute_rich_text_tags
    MeetingMinute::RICH_TEXT_TAGS
  end

  def minute_rich_text(content)
    normalized_content = content.to_s.gsub(/&nbsp;|\u00A0/, " ")
    sanitized = sanitize(normalized_content, tags: minute_rich_text_tags, attributes: [])
    return simple_format(sanitized) unless minute_rich_text_markup?(sanitized)

    sanitized
  end

  def minute_rich_text_editor_content(content)
    minute_rich_text(content)
  end

  def minute_rich_text_markup?(content)
    content.match?(%r{</?(?:p|div|strong|b|em|i|u|ul|ol|li|br)\b}i)
  end

  def ai_answer_content(answer)
    text_wrap_classes = "min-w-0 max-w-full whitespace-normal break-words [overflow-wrap:anywhere] [word-break:break-word]"

    blocks = answer.to_s.lines.map(&:strip).reject(&:blank?).map do |line|
      case line
      when /\A(\d+)[.)]\s+(.+)\z/
        ai_answer_step(Regexp.last_match(1), Regexp.last_match(2))
      when /\A[-•]\s+(.+)\z/
        ai_answer_bullet(Regexp.last_match(1))
      when /\A.{1,70}:\z/
        tag.p(line, class: "#{text_wrap_classes} pt-2 text-[13px] font-black uppercase tracking-wide text-red-700 dark:text-red-300")
      else
        tag.p(line, class: "#{text_wrap_classes} text-sm font-semibold leading-7 text-slate-700 dark:text-slate-200")
      end
    end

    tag.div(class: "min-w-0 max-w-full space-y-2.5 overflow-hidden") { safe_join(blocks) }
  end

  def ai_answer_step(number, text)
    tag.div(class: "flex min-w-0 max-w-full gap-3 overflow-hidden rounded-2xl bg-slate-50 px-3 py-2.5 ring-1 ring-slate-100 dark:bg-[#0F172A] dark:ring-[#334155]") do
      safe_join([
        tag.span(number, class: "mt-0.5 grid h-7 w-7 shrink-0 place-items-center rounded-full bg-red-600 text-xs font-black text-white shadow-sm shadow-red-950/10 dark:bg-red-500"),
        tag.p(text, class: "min-w-0 max-w-full flex-1 whitespace-normal break-words text-sm font-semibold leading-7 text-slate-800 [overflow-wrap:anywhere] [word-break:break-word] dark:text-slate-100")
      ])
    end
  end

  def ai_answer_bullet(text)
    tag.div(class: "flex min-w-0 max-w-full gap-3 overflow-hidden rounded-xl px-3 py-1.5") do
      safe_join([
        tag.span("", class: "mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-red-500"),
        tag.p(text, class: "min-w-0 max-w-full flex-1 whitespace-normal break-words text-sm font-semibold leading-6 text-slate-700 [overflow-wrap:anywhere] [word-break:break-word] dark:text-slate-200")
      ])
    end
  end

  def global_search_result_path(type, record)
    case type.to_sym
    when :members
      admin_user_roles_path(query: record.full_name) if current_user.super_admin?
    when :minutes
      meeting_minute_path(record)
    when :documents
      document_path(record)
    end
  end

  def global_search_result_title(type, record)
    case type.to_sym
    when :members then record.full_name
    else record.title
    end
  end

  def global_search_result_subtitle(type, record)
    case type.to_sym
    when :members
      [ record.membership_number, role_label(record.user.role) ].compact_blank.join(" · ")
    when :minutes
      [ record.meeting_date.strftime("%b %d, %Y"), record.meeting_time_label ].join(" · ")
    when :documents
      record.document_category.name
    when :events
      [ record.event_category.name, record.start_time.strftime("%b %d, %Y") ].join(" · ")
    when :announcements
      [ record.category.humanize, record.published_at&.strftime("%b %d, %Y") ].compact.join(" · ")
    end
  end

  def formatted_file_size(record)
    number_to_human_size(record.file_size)
  end

  def compact_count(value)
    number_to_human(value || 0, precision: 3, significant: false, units: { thousand: "K", million: "M" })
  end

  def google_oauth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def profile_completion_percentage(user = current_user)
    user&.member_profile&.profile_completion_percentage || 0
  end

  def profile_complete?(user = current_user)
    user&.profile_complete? || false
  end

  def user_avatar(user = current_user, classes: "h-9 w-9", text_classes: "text-sm")
    base_classes = "#{classes} overflow-hidden rounded-full bg-[#0F172A] text-white dark:bg-[#334155] dark:text-[#F8FAFC]"
    profile = user&.member_profile

    if profile&.avatar&.attached?
      image_tag avatar_thumbnail(profile.avatar),
        alt: user.display_name,
        class: "#{base_classes} object-cover",
        loading: "lazy",
        decoding: "async"
    else
      content_tag :span,
        (user&.display_name&.first&.upcase || "M"),
        class: "grid place-items-center font-black #{text_classes} #{base_classes}"
    end
  end

  def avatar_thumbnail(avatar)
    image_variant_or_original(avatar, resize_to_fill: [ 96, 96 ], saver: { quality: 82 })
  end

  def image_variant_or_original(image, **options)
    return image unless image_variant_processor_available?

    image.variant(**options)
  rescue ActiveStorage::InvariableError, ActiveStorage::UnrepresentableError
    image
  end

  def image_variant_processor_available?
    return @image_variant_processor_available unless @image_variant_processor_available.nil?

    @image_variant_processor_available = case ActiveStorage.variant_processor
    when :vips
      require "vips"
      true
    when :mini_magick
      require "mini_magick"
      true
    else
      false
    end
  rescue LoadError
    false
  end

  def persisted_attachment?(attachment)
    attachment.attached? && attachment.attachment.persisted? && attachment.blob.persisted?
  end

  def whatsapp_url_for(profile, message: nil)
    url = profile&.whatsapp_url
    return if url.blank?
    return url if message.blank?

    "#{url}?text=#{URI.encode_www_form_component(message)}"
  end

  def payment_receipt_whatsapp_message(payment, sender: current_user)
    member_name = payment.user&.display_name || "Member"
    sender_name = sender&.display_name.presence || "MSJ Finance Team"
    sender_role = sender.present? ? User.role_label(sender.role) : "Finance Team"
    status_line = if payment.paid?
      "Status: Paid"
    elsif payment.pending_verification?
      "Status: Received for verification"
    else
      "Status: Waiting transfer"
    end
    date_line = if payment.paid_on.present?
      "Paid on: #{payment.paid_on.strftime('%b %d, %Y')}"
    elsif payment.transferred_on.present?
      "Transfer date: #{payment.transferred_on.strftime('%b %d, %Y')}"
    else
      "Date: Not recorded yet"
    end

    [
      "Chibai #{member_name},",
      "",
      "MSJ Payment Receipt",
      "Payment/Fund: #{payment.membership_plan.name}",
      "Payment for: #{payment.beneficiary_label}",
      "Type: #{payment.plan_type_label}",
      "Period: #{payment.period_label}",
      "Amount: #{yen(payment.amount)}",
      status_line,
      date_line,
      ("Reference: #{payment.reference_number}" if payment.reference_number.present?),
      "",
      "Confirmed by: #{sender_name} (#{sender_role})",
      "Mizo Society of Japan",
      "",
      "Thank you."
    ].compact.join("\n")
  end

  def payment_receipt_label(payment)
    return "Receipt sent" if payment.receipt_sent?
    return "Receipt ready" if payment.receipt_sendable?
    return "Verify first" unless payment.paid?

    "No WhatsApp"
  end

  def payment_receipt_badge_classes(payment)
    if payment.receipt_sent?
      "bg-emerald-50 text-emerald-700 ring-emerald-200"
    elsif payment.receipt_sendable?
      "bg-sky-50 text-sky-700 ring-sky-200"
    elsif payment.paid?
      "bg-slate-100 text-slate-700 ring-slate-200"
    else
      "bg-amber-50 text-amber-700 ring-amber-200"
    end
  end
end
