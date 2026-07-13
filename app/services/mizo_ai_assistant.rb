require "net/http"
require "json"

class MizoAiAssistant
  OPENAI_ENDPOINT = URI("https://api.openai.com/v1/chat/completions")
  BANK_TRANSFER_QUESTIONS = [
    { key: :yuucho_transfer, text: "Yuucho bank atangin transfer engtin nge ka tih ang?", answer: :yuucho_transfer_answer },
    { key: :other_bank_transfer, text: "Bank dang atangin transfer engtin nge ka tih ang?", answer: :other_bank_transfer_answer }
  ].map(&:freeze).freeze

  ROLE_QUESTION_CATALOG = {
    member: [
      { key: :member_access, text: "Member account hian eng nge ka tih theih?", answer: :member_general_answer },
      { key: :pay_together, text: "Fee leh fund te vawi khat bank transfer-in engtin nge ka pek ang?", answer: :payment_answer },
      *BANK_TRANSFER_QUESTIONS,
      { key: :submit_and_track, text: "Transfer zawh hnuah eng nge ka submit a, status engtin nge ka check ang?", answer: :payment_submission_status_answer },
      { key: :family_fee, text: "Kum 14+ child membership fee hi engtin nge ka pek ang?", answer: :family_fee_answer },
      { key: :welfare_request, text: "Welfare support private taka engtin nge ka dil ang?", answer: :welfare_answer },
      { key: :events_and_updates, text: "Events, RSVP leh announcements engtin nge ka hman ang?", answer: :member_events_updates_answer },
      { key: :account_help, text: "Password ka theihnghilh emaw sign in harsatna ka neih chuan engtin nge ka tih ang?", answer: :account_answer }
    ],
    super_admin: [
      { key: :admin_access, text: "Super Admin daily checklist leh portal control dan min hrilh rawh.", answer: :super_admin_general_answer },
      { key: :review_transfers, text: "Submitted payment batch approve/reject dan min hrilh rawh.", answer: :payment_review_answer },
      { key: :plans_and_duplicates, text: "Payment plans manage leh duplicate payment ven dan eng nge?", answer: :payment_plan_answer },
      { key: :family_fee_setup, text: "Kum 14+ child membership fee engtin nge ka setup ang?", answer: :family_fee_answer },
      { key: :finance_operations, text: "Transactions leh yearly finance report check dan min hrilh rawh.", answer: :finance_operations_answer },
      { key: :manage_welfare, text: "Welfare case assign/resolve dan eng nge?", answer: :welfare_answer },
      { key: :manage_minutes, text: "Meeting minutes siam leh publish dan min hrilh rawh.", answer: :minutes_answer },
      { key: :manage_updates, text: "Events leh announcements manage dan eng nge?", answer: :event_announcement_management_answer },
      { key: :manage_letters, text: "Official letter siam leh download dan min hrilh rawh.", answer: :letters_answer },
      { key: :manage_roles, text: "User role assign, change leh deactivate dan min hrilh rawh.", answer: :role_management_answer },
      { key: :governance, text: "Settings, Permissions leh Audit Logs hman dan eng nge?", answer: :settings_answer },
      { key: :admin_own_payment, text: "Mahni fee leh fund te engtin nge ka pek ang?", answer: :payment_answer },
      *BANK_TRANSFER_QUESTIONS
    ],
    finance_admin: [
      { key: :finance_access, text: "Finance Admin daily workflow leh access chin min hrilh rawh.", answer: :finance_admin_general_answer },
      { key: :review_transfers, text: "Combined transfer verify, approve leh reject dan eng nge?", answer: :payment_review_answer },
      { key: :manual_payment, text: "Manual payment record duplicate lovin engtin nge ka siam ang?", answer: :manual_payment_answer },
      { key: :manage_plans, text: "Payment plans engtin nge ka manage ang?", answer: :payment_plan_answer },
      { key: :family_fee_setup, text: "Kum 14+ child membership fee engtin nge ka setup ang?", answer: :family_fee_answer },
      { key: :transactions, text: "Income leh expense transaction record dan min hrilh rawh.", answer: :finance_transactions_answer },
      { key: :finance_reports, text: "Finance report leh CSV export engtin nge ka hman ang?", answer: :reports_answer },
      { key: :finance_own_payment, text: "Mahni fee leh fund te engtin nge ka pek ang?", answer: :payment_answer },
      *BANK_TRANSFER_QUESTIONS
    ],
    assistant_secretary: [
      { key: :assistant_access, text: "Assistant Secretary daily workflow leh access chin min hrilh rawh.", answer: :assistant_secretary_general_answer },
      { key: :manage_welfare, text: "Welfare case assign/resolve dan eng nge?", answer: :welfare_answer },
      { key: :manage_minutes, text: "Meeting minutes siam leh publish dan min hrilh rawh.", answer: :minutes_answer },
      { key: :manage_updates, text: "Events leh announcements manage dan eng nge?", answer: :event_announcement_management_answer },
      { key: :manage_letters, text: "Official letter siam leh download dan min hrilh rawh.", answer: :letters_answer },
      { key: :assistant_own_payment, text: "Mahni fee leh fund te engtin nge ka pek ang?", answer: :payment_answer },
      *BANK_TRANSFER_QUESTIONS
    ],
    office_bearer_viewer: [
      { key: :observer_access, text: "Vice President/Journal Secretary access leh responsibility eng nge?", answer: :observer_general_answer },
      { key: :view_finance, text: "Finance leh Payment Records view-only anga en dan eng nge?", answer: :finance_viewer_answer },
      { key: :view_minutes_letters, text: "Minutes leh Letters ka en/download theih chin eng nge?", answer: :observer_minutes_letters_answer },
      { key: :view_welfare, text: "Welfare records view-only anga en dan eng nge?", answer: :welfare_answer },
      { key: :view_reports, text: "Reports ka hmuh leh export theih chin eng nge?", answer: :reports_answer },
      { key: :observer_updates, text: "Events leh announcements engtin nge ka en ang?", answer: :member_events_updates_answer },
      { key: :observer_own_payment, text: "Mahni fee leh fund te engtin nge ka pek ang?", answer: :payment_answer },
      *BANK_TRANSFER_QUESTIONS
    ],
    executive: [
      { key: :executive_access, text: "Executive Committee member access leh responsibility eng nge?", answer: :executive_general_answer },
      { key: :executive_payment, text: "Mahni fee leh fund te engtin nge ka pek ang?", answer: :payment_answer },
      { key: :executive_minutes, text: "Minutes ka en/download theih chin eng nge?", answer: :minutes_answer },
      { key: :executive_welfare, text: "Welfare records view-only anga en dan eng nge?", answer: :welfare_answer },
      { key: :executive_reports, text: "Reports ka hmuh leh export theih chin eng nge?", answer: :reports_answer },
      { key: :executive_updates, text: "Events leh announcements engtin nge ka en ang?", answer: :member_events_updates_answer },
      *BANK_TRANSFER_QUESTIONS
    ]
  }.transform_values { |questions| questions.map(&:freeze).freeze }.freeze

  def self.call(user:, question:)
    new(user: user, question: question).call
  end

  def self.suggested_questions(user:)
    question_entries(user: user).pluck(:text)
  end

  def self.question_entries(user:)
    ROLE_QUESTION_CATALOG.fetch(role_key(user))
  end

  def self.role_key(user)
    return :super_admin if user.super_admin?
    return :finance_admin if user.finance_admin?
    return :assistant_secretary if user.assistant_secretary?
    return :office_bearer_viewer if user.observer_office_bearer?
    return :executive if user.executive_committee?

    :member
  end

  def initialize(user:, question:)
    @user = user
    @question = question.to_s.strip
  end

  def call
    return blank_question_answer if question.blank?

    answer = curated_answer
    return answer if answer

    if openai_available?
      openai_answer.presence || fallback_answer
    else
      fallback_answer
    end
  rescue StandardError => error
    Rails.logger.warn("AI assistant fallback for user_id=#{user&.id}: #{error.class} - #{error.message}")
    fallback_answer
  end

  private

  attr_reader :user, :question

  def curated_answer
    @curated_answer ||= begin
      entry = self.class.question_entries(user: user).find { |item| item[:text] == question }
      entry && send(entry.fetch(:answer))
    end
  end

  def openai_available?
    ENV["OPENAI_API_KEY"].present?
  end

  def openai_answer
    request = Net::HTTP::Post.new(OPENAI_ENDPOINT)
    request["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: ENV.fetch("OPENAI_ASSISTANT_MODEL", "gpt-4o-mini"),
      temperature: 0.2,
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: user_prompt }
      ]
    }.to_json

    response = Net::HTTP.start(OPENAI_ENDPOINT.hostname, OPENAI_ENDPOINT.port, use_ssl: true, read_timeout: 20, open_timeout: 5) do |http|
      http.request(request)
    end

    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).dig("choices", 0, "message", "content").to_s.strip
  end

  def system_prompt
    <<~PROMPT.squish
      You are the MSJ Portal assistant for Mizo Society of Japan.
      Reply mainly in simple, polite Mizo language.
      Use clear step-by-step answers for non-technical users.
      Only use the provided portal context.
      Do not invent rules, private records, payment confirmation, or official decisions.
      If the question is outside MSJ Portal, MSJ activities, membership, payments, profile, welfare, events, minutes, letters, or reports, politely say you do not know and ask the user to contact an Office Bearer.
      If the context is not enough, say clearly that the user should contact an Office Bearer.
      Respect role permissions and never reveal confidential welfare, finance, or member data.
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      User role: #{User.role_label(user.role)}
      User name: #{user.display_name}

      Portal context:
      #{context_lines.join("\n")}

      Important response rules:
      - Answer for this user's role only.
      - If this role can only view, do not give create/edit/approve instructions.
      - If this role cannot access a feature, say it is not available for this role.
      - Super Admin can receive complete portal management steps.
      - Vice President and Journal Secretary are Office Bearer view-only roles for most admin pages.
      - Executive Committee can view permitted records but should not receive edit/approve/export instructions.
      - Members should receive only member-facing guidance.
      - Prefer practical steps using visible page names in the portal.
      - Use Japanese banking terms with romaji/explanation in brackets when helpful.

      User question:
      #{question}
    PROMPT
  end

  def context_lines
    [
      role_context,
      navigation_context,
      dashboard_context,
      payment_context,
      profile_context,
      welfare_context,
      event_context,
      minutes_context,
      letters_context,
      admin_context
    ].compact
  end

  def role_context
    permissions = []
    permissions << "pay own fees and funds"
    permissions << "update own profile"
    permissions << "submit own welfare requests"
    permissions << "view and RSVP visible events"
    permissions << "view reports" if user.report_viewer?
    permissions << "view meeting minutes" if user.minutes_access?
    permissions << "manage payments/finance records" if user.finance_admin? || user.super_admin?
    permissions << "approve/reject submitted transfers" if user.finance_approver?
    permissions << "manage welfare cases" if user.welfare_manager?
    permissions << "manage events, official letters, and minutes" if user.event_manager? || user.minute_manager?
    permissions << "manage settings, user roles, and audit logs" if user.super_admin?
    permissions << "view-only office bearer areas" if user.observer_office_bearer?
    permissions << "view-only executive committee areas" if user.executive_committee?

    restrictions = role_restrictions

    "Role: #{User.role_label(user.role)}. Allowed: #{permissions.uniq.join(', ')}. Restrictions: #{restrictions.join(', ')}."
  end

  def role_restrictions
    return [ "full portal control, but payment confirmation and role changes must still follow real records and audit accountability" ] if user.super_admin?
    return [ "can manage finance records but cannot change settings, user roles, or audit logs" ] if user.finance_admin?
    return [ "can manage welfare, events, minutes, and letters but cannot approve finance unless also President/Secretary, and cannot change settings/user roles" ] if user.assistant_secretary?
    return [ "Office Bearer view-only for most admin areas; can pay own fees/funds; cannot approve, edit, delete, export confidential CSV, change settings, or change roles" ] if user.observer_office_bearer?
    return [ "Executive Committee view-only; can pay own fees/funds; cannot approve, edit, delete, export CSV, change settings, or change roles" ] if user.executive_committee?

    [ "member-only access; cannot view private admin, finance approval, role management, audit logs, or confidential welfare records" ]
  end

  def navigation_context
    pages = [ "Dashboard", "Payments", "AI Assistant", "Welfare", "Events", "Profile" ]
    pages << "Minutes" if user.minutes_access?
    pages << "Reports" if user.report_viewer?
    pages += [ "Payment Records", "Payment Plans", "Transactions" ] if user.finance_viewer?
    pages += [ "Letters" ] if user.event_manager? || user.office_bearer? || user.minutes_access?
    pages += [ "Settings", "User Roles", "Audit Logs", "Permissions" ] if user.super_admin?

    "Visible/expected pages for this role: #{pages.uniq.join(', ')}."
  end

  def dashboard_context
    if user.operations_team?
      "Dashboard: Admin/Office Bearer dashboard shows member activity, payment review, welfare, meeting minutes, upcoming events, official letters, and yearly finance overview according to role permissions."
    else
      "Dashboard: Member dashboard focuses on own payments, profile completion, announcements/updates, visible events, welfare support, and basic member community summary. It should not expose private admin data."
    end
  end

  def payment_context
    pending_count = user.membership_payments.pending.count
    pending_verification_count = user.payment_batches.pending_verification.count + user.membership_payments.pending_verification.where(payment_batch_id: nil).count

    "Payments: Members should use Payments page to select unpaid fees/funds, including separate eligible child fees shown under a parent account, pay together by one bank transfer, then submit transfer date, amount, and reference name. Screenshot is optional unless Office Bearers request it. Paid/approved items should not remain in current unpaid payments. Bank transfer is the main method. Yuucho-to-Yuucho transfer uses 記号 (kigou / symbol) and 番号 (bangou / number). Transfers from other banks use 店名 (tenmei / store name) and 口座番号 (kouza bangou / account number). Current user has #{pending_count} waiting transfer and #{pending_verification_count} pending verification."
  end

  def profile_context
    profile = user.member_profile
    completion = profile&.profile_completion_percentage || 0

    "Profile: Members must complete full name, Japan mobile number, date of birth, family status, postal code, prefecture, city, and address line 1 before using protected portal areas. Father name, mother name, spouse name, and family members may be captured for member records. Avatar/profile photo is optional. Current profile completion is #{completion}%."
  end

  def welfare_context
    if user.welfare_manager?
      "Welfare: President, Secretary, and Assistant Secretary can manage welfare cases, assign authorized Office Bearers, resolve, and reject cases. Other permitted office/executive viewers may only view according to role."
    else
      "Welfare: Members can submit private support requests from Welfare Support. Details are visible only to authorized Office Bearers. Members should share only necessary information."
    end
  end

  def event_context
    upcoming_count = EventPolicy::Scope.new(user, Event).resolve.upcoming.count

    "Events/Announcements: Members can view published events and portal announcements/updates visible to their role and RSVP when registration is open. Current visible upcoming event count is #{upcoming_count}."
  end

  def minutes_context
    return "Minutes: This user does not have meeting minutes access." unless user.minutes_access?

    "Minutes: Office Bearers and permitted Executive Committee users can view meeting minutes according to visibility rules. President, Secretary, and Assistant Secretary can manage minutes."
  end

  def letters_context
    if user.event_manager?
      "Letters: President, Secretary, and Assistant Secretary can prepare official letters. Other users only see letters visible to their role."
    else
      "Letters: Official letters are visible only when permitted by role and visibility."
    end
  end

  def admin_context
    return unless user.operations_team?

    "Admin: Finance viewers can view finance areas according to role. Payment approval is for President, Secretary, Treasurer, and Finance Secretary. Vice President and Journal Secretary are Office Bearer view-only for most admin areas. Settings, audit logs, and user roles are President/Secretary super-admin only."
  end

  def fallback_answer
    normalized = question.downcase

    if outside_portal_question?(normalized)
      outside_portal_answer
    elsif includes_any?(normalized, "yuucho", "ゆうちょ", "yucho", "jp bank")
      yuucho_transfer_answer
    elsif includes_any?(normalized, "other bank", "mufg", "smbc", "mizuho", "branch", "store name", "store", "bank dang", "another bank")
      other_bank_transfer_answer
    elsif includes_any?(normalized, "ka role", "my role", "tih theih", "access", "permission", "sidebar", "view-only", "view only", "hmuh theih", "role base", "role-based")
      role_access_answer
    elsif includes_any?(normalized, "dashboard", "stat", "summary", "overview")
      dashboard_answer
    elsif includes_any?(normalized, "screenshot", "reference name", "transfer date", "submit transfer", "amount due", "current payment", "payment history", "receipt", "approved", "paid")
      payment_answer
    elsif includes_any?(normalized, "approve", "verify", "verification", "treasurer", "reject", "review")
      payment_review_answer
    elsif includes_any?(normalized, "payment plan", "payment plans", "plan", "fundraiser", "donation", "chhiatni", "plan type")
      payment_plan_answer
    elsif includes_any?(normalized, "payment", "fee", "fund", "bank", "transfer", "pawisa", "pek", "paid")
      payment_answer
    elsif includes_any?(normalized, "profile", "address", "mobile", "phone", "postal", "complete", "avatar", "photo", "father", "mother", "family", "spouse", "date of birth")
      profile_answer
    elsif includes_any?(normalized, "welfare", "support", "help", "tanpuina", "chhiah")
      welfare_answer
    elsif includes_any?(normalized, "announcement", "notice", "updates")
      announcement_answer
    elsif includes_any?(normalized, "event", "rsvp", "programme", "program")
      event_answer
    elsif includes_any?(normalized, "minute", "meeting", "record", "signature", "pdf", "publish", "draft", "attendance", "agenda", "decision", "resolution")
      minutes_answer
    elsif includes_any?(normalized, "letter", "official", "document", "documents", "docx", "subject", "archive final", "reference no")
      letters_answer
    elsif includes_any?(normalized, "report", "csv", "export")
      reports_answer
    elsif includes_any?(normalized, "setting", "role", "user role", "permission", "audit")
      settings_answer
    elsif includes_any?(normalized, "notification", "bell", "read")
      notification_answer
    elsif includes_any?(normalized, "login", "sign in", "password", "google", "forgot")
      account_answer
    elsif includes_any?(normalized, "finance")
      admin_answer
    else
      general_answer
    end
  end

  def dashboard_answer
    if user.operations_team?
      <<~ANSWER.strip
        Dashboard-ah i hmuh tur chu i role azirin a inang lo thei:

        1. Member summary leh new member activity.
        2. Payment review/pending verification summary.
        3. Welfare case summary.
        4. Meeting minutes leh upcoming events.
        5. Official letters leh yearly finance overview.

        Card thenkhat a lang loh chuan i role permission emaw data awm loh vang emaw a ni thei.
      ANSWER
    else
      <<~ANSWER.strip
        Member dashboard-ah i hmuh tur pawimawh te:

        1. Own payments leh pending transfer status.
        2. Profile completion.
        3. Announcements/updates.
        4. Upcoming events.
        5. Welfare support link.

        Private admin data, finance details, welfare confidential records te member dashboard-ah a lang lo tur a ni.
      ANSWER
    end
  end

  def role_access_answer
    if user.super_admin?
      super_admin_general_answer
    elsif user.finance_admin?
      finance_admin_general_answer
    elsif user.assistant_secretary?
      assistant_secretary_general_answer
    elsif user.observer_office_bearer?
      observer_general_answer
    elsif user.executive_committee?
      executive_general_answer
    else
      member_general_answer
    end
  end

  def payment_answer
    <<~ANSWER.strip
      Payment tih dan chu heti hian kal rawh:

      1. Payments page-ah lut rawh.
      2. Pek tur fee/fund te checkbox-in thlang rawh.
      3. Fee/fund tam tak i thlang thei. A vaiin bank transfer vawi khat chauh i ti ang.
      4. Portal-a total amount lo lang kha i bank app/ATM-ah transfer rawh.
      5. Transfer i zawh hnuah portal-ah transfer date, amount, leh reference name submit rawh.
      6. Treasurer/Finance team-in bank record nen verify hnuah Paid-ah a inthlak ang.
      7. Paid a nih chuan notification-ah i hmu thei ang.
      8. Finance team-in WhatsApp receipt an thawn thei, mahse receipt chu bank verification zawh hnuah chauh official a ni.

      Screenshot chu optional a ni, mahse transfer verify a awlsam zawk nan upload theih a ni.

      Yuucho bank i hmang chuan “Yuucho to Yuucho” guide en rawh. Bank dang i hmang chuan “From another bank” guide en rawh.
    ANSWER
  end

  def payment_submission_status_answer
    <<~ANSWER.strip
      Bank transfer i tih zawh hnuah heti hian kal rawh:

      1. Payments page-ah kir leh rawh.
      2. Transfer date chu bank transfer i tih ni dik tak thlang rawh.
      3. Transfer amount chu portal-a selected total nen a inmil ngei tur a ni.
      4. Reference name-ah bank account-a sender name lo lang tur kha check rawh.
      5. Screenshot chu optional a ni; transfer hriat hran a harsat chuan upload rawh.
      6. Submit Transfer click rawh. Status chu Pending Verification-ah a inthlak ang.
      7. Treasurer emaw Finance Secretary-in bank record nen verify hnuah Paid-ah a inthlak ang.
      8. Payments history leh notification-ah approval i check thei ang. WhatsApp receipt an thawn chuan approved payment receipt a ni.

      Pending Verification la nih chhung chuan payment nawn leh suh. Reject a nih chuan reason en la, transfer details dik takin submit leh rawh.
    ANSWER
  end

  def family_fee_answer
    if user.super_admin? || user.finance_admin?
      <<~ANSWER.strip
        Kum 14+ child membership fee setup dan:

        1. Payment Plans page-ah membership fee plan open la Edit Plan click rawh.
        2. Required for all members tih enable rawh.
        3. Charge eligible children aged 14 or older tih enable rawh.
        4. Fee per eligible child amount chu whole yen-in dah rawh.
        5. Save hnuah family profile-a date of birth recorded, kum 14 tling tawh child-te parent/guardian account Payments page-ah record hranin an lo lang ang.
        6. Parent fee leh child fee te checkbox-in select kawp a, bank transfer vawi khat chauh tih theih a ni.
        7. Payment Records review-ah For child name leh child membership number check la, bank transfer verify hnuah approve rawh.

        Child tan login account hran siam a ngai lo. Date of birth awm lo child chu automatic charge a nei lo ang.
      ANSWER
    else
      <<~ANSWER.strip
        Kum 14+ child membership fee pek dan:

        1. Profile page-ah Family Status chu Family thlang la, child name leh date of birth dah rawh.
        2. MSJ-in child fee plan enable a, child kum 14 a tlin chuan parent/guardian Payments page-ah For child name tih nen fee hran a lo lang ang.
        3. Parent fee leh child fee te checkbox-in select kawp rawh.
        4. Pay Together click la, total amount chu bank transfer vawi khat chauh ti rawh.
        5. Transfer date, total amount leh reference name submit rawh.
        6. Treasurer/Finance team-in verify hnuah child fee record chu Paid-ah a inthlak ang.

        Child tan email/password account hran siam a ngai lo.
      ANSWER
    end
  end

  def member_events_updates_answer
    <<~ANSWER.strip
      Events leh announcements hman dan:

      1. Events page-ah published events leh latest announcements en rawh.
      2. Event card-a View click la, date, time, venue leh registration details check rawh.
      3. Registration required a nih chuan RSVP button hmang rawh.
      4. I kal theih loh chuan registration close hma in RSVP update/cancel rawh.
      5. Announcement pawimawh leh pinned notice chu dashboard-ah pawh a lang thei.
      6. Draft, expired, emaw i role tana visible lo notice/event chu a lang lo ang.
    ANSWER
  end

  def finance_operations_answer
    <<~ANSWER.strip
      Transactions leh yearly finance report check dan:

      1. Transactions page-ah income leh expense records, date, category, amount leh approval status check rawh.
      2. Record thar siam hma in same payment/receipt record a awm tawh em search rawh.
      3. Payment approval atanga income transaction auto-create a nih chuan manual duplicate siam suh.
      4. Reports > Finance-ah current year thlang rawh.
      5. Total income, total expense leh balance te transaction list nen compare rawh.
      6. CSV export hma in filter year/date range dik em check rawh.
      7. Figure a inmil loh chuan record delete nghal lovin source payment leh audit trail check phawt rawh.
    ANSWER
  end

  def manual_payment_answer
    <<~ANSWER.strip
      Manual payment record duplicate lova siam dan:

      1. Payment Records page-ah member name emaw membership number-in search rawh.
      2. Same member, payment plan, year leh period-a Waiting Transfer, Pending Verification, emaw Paid record a awm em check rawh.
      3. Existing active/paid record a awm chuan New Payment hmang suh; record existing kha open rawh.
      4. Record a awm loh chuan Add Payment click la member leh payment plan thlang rawh.
      5. Plan thlan hnuah amount auto-filled kha plan amount nen verify rawh.
      6. Payment method leh status chu evidence dik tak azirin chauh thlang rawh.
      7. Create Payment hnuah member name, membership number, plan, amount leh period check leh rawh.

      Bank confirmation awm loh chuan Paid status hmang suh.
    ANSWER
  end

  def finance_transactions_answer
    <<~ANSWER.strip
      Income leh expense transaction record dan:

      1. Transactions page-ah existing record search/filter phawt rawh.
      2. New Transaction click la Income emaw Expense thlang rawh.
      3. Transaction date, category, description leh amount dik tak dah rawh.
      4. Amount chu yen whole number-in enter la, decimal point tul lo.
      5. Membership payment approved atanga income auto-create tawh chu manual-in siam nawn suh.
      6. Save hnuah status leh amount check rawh; approval ngai a nih chuan authorized approver-in review rawh.
      7. Edit/Delete hma in report leh audit impact check rawh.
    ANSWER
  end

  def event_announcement_management_answer
    <<~ANSWER.strip
      Events leh announcements manage dan:

      1. Events page-ah lut rawh.
      2. Event thar atan New Event click la title, date, time, venue, description leh registration setting fill up rawh.
      3. Draft-in save la, details check zawh hnuah publish rawh.
      4. Announcement atan Official Notices/Announcements section open rawh.
      5. New Notice click la title, body, pinned setting leh expiry date fill up rawh.
      6. Member-te hriat tur ready a nih chauh publish rawh.
      7. Event/notice update emaw cancel hma in RSVP users leh visible audience ngaihtuah rawh.
    ANSWER
  end

  def role_management_answer
    return settings_answer unless user.super_admin?

    <<~ANSWER.strip
      User role assign/change/deactivate dan:

      1. Settings > User Roles-ah lut rawh.
      2. User name emaw email-in search la current role leh status check rawh.
      3. Edit/Change Role click la official appointment nen inmil role chauh thlang rawh.
      4. Save hma in finance, welfare, minutes, events leh settings access a dawn tur ngaihtuah rawh.
      5. User deactivate hma in active records emaw responsibility la nei em check rawh.
      6. President/Secretary super admin account pakhat tal active reng tur a ni.
      7. Change zawh hnuah Audit Logs-ah action record a awm em check rawh.

      Treasurer, Finance Secretary leh role dangte chuan user role an thlak thei lo.
    ANSWER
  end

  def observer_minutes_letters_answer
    <<~ANSWER.strip
      Minutes leh Letters view-only anga hman dan:

      1. Minutes page-ah i role tana visible published records en rawh.
      2. View click la meeting details chhiar rawh; available a nih chuan PDF download theih a ni.
      3. Letters page-ah i role tana visible official letters en rawh.
      4. Available a nih chuan final letter/download button hmang rawh.
      5. New, Edit, Publish, Archive leh Delete actions chu i role tan available lo a ni.
      6. Correction ngai a awm chuan President, Secretary emaw Assistant Secretary contact rawh.
    ANSWER
  end

  def yuucho_transfer_answer
    <<~ANSWER.strip
      ゆうちょ銀行 (Yuucho Ginko) atanga transfer tih dan chu heti hian kal rawh:

      1. Payments page-ah i pay tur fee/fund thlang rawh.
      2. Total amount lo lang kha note rawh.
      3. ゆうちょ通帳アプリ (Yuucho Tsuuchou App), ゆうちょダイレクト (Yuucho Direct), emaw ゆうちょ ATM open rawh.
      4. ゆうちょ銀行 (Yuucho Ginko) account-a transfer i tih chuan 記号 (kigou / symbol) leh 番号 (bangou / number) hmang rawh.
      5. Portal-a bank details card-ah symbol leh number a hranin a awm ang. Copy button hmangin copy theih a ni.
      6. Amount chu portal-a total amount ang chiah dah rawh.
      7. Transfer zawh hnuah portal-ah kir leh la, transfer date, amount, leh reference name submit rawh.
      8. Treasurer/Finance team-in verify hnuah Paid-ah a inthlak ang.

      Hriat reng tur: Yuucho to Yuucho-ah store name/store number aiin symbol leh number hmang thin a ni.
    ANSWER
  end

  def other_bank_transfer_answer
    <<~ANSWER.strip
      Bank dang atanga ゆうちょ銀行 (Yuucho Ginko) account-a transfer tih dan chu heti hian kal rawh:

      1. Payments page-ah i pay tur fee/fund thlang rawh.
      2. Total amount lo lang kha note rawh.
      3. I bank app open rawh. Entirnan: MUFG, SMBC, Mizuho, emaw bank dang.
      4. 振込 (furikomi / bank transfer) menu thlang rawh.
      5. Bank-ah ゆうちょ銀行 (Yuucho Ginko) thlang rawh.
      6. 店名 (tenmei / store name) emaw branch name leh 口座番号 (kouza bangou / account number) dah rawh. Portal-a bank details card-ah a awm ang.
      7. Amount chu portal-a total amount ang chiah dah rawh.
      8. Account name a rawn lang chuan MSJ bank detail nen a inmil em check rawh.
      9. Transfer zawh hnuah portal-ah kir leh la, transfer date, amount, leh reference name submit rawh.
      10. Treasurer/Finance team-in verify hnuah Paid-ah a inthlak ang.

      Hriat reng tur: Bank dang atanga transfer-ah symbol/number aiin store name/branch leh account number hmang thin a ni.
    ANSWER
  end

  def payment_plan_answer
    if user.finance_viewer?
      manage_text = if user.finance_admin? || user.super_admin?
        "I role-in a phal chuan new/edit/delete controls a lang ang."
      else
        "I role hi view-only a nih chuan new/edit/delete controls a lang lo ang."
      end

      <<~ANSWER.strip
        Payment Plans hman dan:

        1. Payment Plans page-ah lut rawh.
        2. Membership fee, chhiatni fund, donation, fundraiser, fee dang te plan anga siam theih a ni.
        3. Active plan chauh member Payments page-ah unpaid/current payment atan lo lang thei.
        4. Amount, year, due date, plan type, active status te dik takin dah rawh.
        5. #{manage_text}
        6. Same member + same plan + same year/period record a awm tawh chuan record thar siam suh; existing record open la update rawh.

        Plan delete hma chuan payment record existing a inzawm em check rawh.
      ANSWER
    else
      <<~ANSWER.strip
        Payment plan details chu admin/finance side-a siam a ni.

        Member tan:

        1. Payments page-ah i pay tur fee/fund te lo lang ang.
        2. A lo lang loh chuan Office Bearer emaw Treasurer/Finance team contact rawh.
        3. Plan amount dik lo angin i hria chuan approve/payment submit hma in zawt rawh.
      ANSWER
    end
  end

  def profile_answer
    completion = user.member_profile&.profile_completion_percentage || 0

    <<~ANSWER.strip
      Profile complete tur chuan heng hi fill up rawh:

      1. Full name
      2. Japan mobile number
      3. Date of birth
      4. Family status
      5. Postal code
      6. Prefecture
      7. City
      8. Address line 1

      Tuna i profile completion: #{completion}%.
      Profile page-ah lut la, missing field awm chu update rawh.

      Profile photo/avatar chu optional a ni. Clear face photo upload chuan member profile-ah hriat awlsam zawk a ni ang.
    ANSWER
  end

  def welfare_answer
    return welfare_manager_answer if user.welfare_manager?
    return welfare_viewer_answer if user.welfare_viewer?

    <<~ANSWER.strip
      Welfare support dil dan:

      1. Welfare page-ah lut rawh.
      2. Request Support click rawh.
      3. Support type, urgency, leh i mamawh thu tawi fel takin ziak rawh.
      4. Attachment a ngaih chuan PDF/JPG/PNG upload theih a ni.
      5. Authorized Office Bearers chauhin a en ang.

      Confidential thil a nih avangin, tul chauh share rawh.
    ANSWER
  end

  def welfare_viewer_answer
    <<~ANSWER.strip
      Welfare page i role tan view-only angin a awm thei.

      I tih theih:

      1. Welfare page-ah lut rawh.
      2. I role-in a phal chin case details en rawh.
      3. Confidential information chu share loh tur.
      4. Case update ngai a awm chuan President, Secretary, emaw Assistant Secretary contact rawh.

      I role-in manage permission a neih loh chuan assign/resolve/reject button a lang lo ang.
    ANSWER
  end

  def welfare_manager_answer
    <<~ANSWER.strip
      Welfare case enkawl dan:

      1. Welfare page-ah lut rawh.
      2. Open/In progress case te en rawh.
      3. Case details chhiar la, tul chuan authorized Office Bearer assign rawh.
      4. Member privacy vawng tha rawh. Tul loh information share suh.
      5. Support tihfel a nih chuan status update rawh.
      6. Resolve/Reject tih hma chuan record leh note fel tak dah rawh.
    ANSWER
  end

  def event_answer
    return event_manager_answer if user.event_manager?

    <<~ANSWER.strip
      Event hman dan:

      1. Events page-ah lut rawh.
      2. Upcoming event details en rawh.
      3. Registration required a nih chuan RSVP button hmang rawh.
      4. I kal theih loh chuan RSVP withdraw/cancel theih a ni, event page-ah a awm ang.
    ANSWER
  end

  def event_manager_answer
    <<~ANSWER.strip
      Event enkawl dan:

      1. Events page-ah lut rawh.
      2. New Event hmangin event thar siam rawh.
      3. Title, date, time, venue, description, registration setting te fill up rawh.
      4. Draft-in save la, ready chuan publish rawh.
      5. Published event chauh member te tan a lang ang.
      6. Registration required a nih chuan RSVP list en theih a ni.

      Event cancel/complete tih hma chuan member notification leh real programme status check rawh.
    ANSWER
  end

  def minutes_answer
    if user.minute_manager?
      <<~ANSWER.strip
        Meeting minutes siam/enkawl dan:

        1. Minutes page-ah lut rawh.
        2. New Minute click rawh.
        3. Meeting title, date, time, venue, attendance, agenda, decisions/resolutions fill up rawh.
        4. Chairman/Secretary signature upload a ngaih chuan PNG file hmang rawh.
        5. Draft-in save la, ready chuan Publish button hmang rawh.
        6. View page-ah Export PDF hmangin A4 minute download theih a ni.

        President, Secretary, Assistant Secretary te chauhin minutes manage theih a ni.
      ANSWER
    elsif user.minutes_access?
      <<~ANSWER.strip
        Meeting minutes en dan:

        1. Minutes page-ah lut rawh.
        2. Published minutes i role-in a phal chin chauh a lang ang.
        3. View button hmangin minute details en rawh.
        4. Download/Export PDF a phal chuan button a lang ang.

        I role hi view-only a nih chuan edit/delete/publish a lang lo ang.
      ANSWER
    else
      "Meeting minutes hi role-based a ni. I account-in access a neih loh chuan a lang lo ang."
    end
  end

  def announcement_answer
    if user.event_manager?
      <<~ANSWER.strip
        Announcement/Notice siam dan:

        1. Events page-ah lut rawh.
        2. Announcements/Official Notices section-ah kal rawh.
        3. New Notice click la, title, category, body, pinned setting, expires date te fill up rawh.
        4. Save Draft hmang la, ready chuan Publish rawh.
        5. Published notice chauh member dashboard leh Events page-ah lang ang.
        6. Notice pawimawh chu pinned-a dah theih a ni.

        Announcement hi member zawng zawng hriat tur official update atan hmang rawh.
      ANSWER
    else
      <<~ANSWER.strip
        Announcement/Updates en dan:

        1. Dashboard-ah Announcements & Updates card en rawh.
        2. Events page-ah Latest Announcements section a awm bawk ang.
        3. Notice title click chuan details i en thei.
        4. Pinned notice chu pawimawh bik a ni.

        Member role chuan published notice chauh a hmu ang.
      ANSWER
    end
  end

  def letters_answer
    if user.event_manager?
      <<~ANSWER.strip
        Official letter siam dan:

        1. Letters page-ah lut rawh.
        2. New Letter click rawh.
        3. Letter title, reference no, date, recipient, subject, body, President/Secretary contact details fill up rawh.
        4. Preview-ah layout check rawh.
        5. Save draft emaw publish/archive final file emaw i duh angin hmang rawh.
        6. Download DOCX hmangin official letter format download theih a ni.

        Subject chu formal letter-ah bold-in lang tur a ni. Preview leh download format inang theih ang berin siam a ni.
      ANSWER
    elsif user.office_bearer? || user.minutes_access?
      "Official letters chu Letters page-ah i role-in a phal chin chauh i en/download thei ang. I role hi view-only a nih chuan new/edit/delete a lang lo ang."
    else
      "Official letters chu Letters page-ah awm a ni. Letter visibility a zirin i role-in a hmuh theih chin chauh a lang ang."
    end
  end

  def admin_answer
    return finance_viewer_answer if user.finance_viewer? && !user.finance_approver?
    return non_admin_answer unless user.finance_approver? || user.super_admin? || user.welfare_manager? || user.event_manager? || user.minute_manager?

    <<~ANSWER.strip
      Admin/verification kal dan:

      1. Payment Records page-ah pending verification records en rawh.
      2. Member transfer date, amount, reference name, leh screenshot a awm chuan check rawh.
      3. Bank account record nen a inmil chuan Approve rawh.
      4. A inmil loh chuan Reject rawh, member-in update leh theih nan.
      5. Same member + same plan + same year/period-a paid/active record a awm tawh chuan add payment thar siam suh.

      Payment confirm loh chuan Paid-ah mark suh.
    ANSWER
  end

  def payment_review_answer
    return finance_viewer_answer if user.finance_viewer? && !user.finance_approver?
    return non_admin_answer unless user.finance_approver?

    <<~ANSWER.strip
      Payment approve/reject dan:

      1. Payment Records page-ah lut rawh.
      2. Pending Verification status-a records/batches en rawh.
      3. Review button click la, member transfer date, amount, reference name, leh screenshot a awm chuan check rawh.
      4. Bank account real record nen amount leh sender/reference name a inmil em verify rawh.
      5. A dik chuan Approve rawh. A dik loh chuan Reject rawh, member-in submit leh theih nan.
      6. Duplicate record awm chuan new payment siam lovin existing record update rawh.

      Payment confirm loh chuan Paid-ah mark suh.
    ANSWER
  end

  def finance_viewer_answer
    if user.observer_office_bearer?
      <<~ANSWER.strip
        Finance page hi i role tan view-only a ni.

        I tih theih:

        1. Payments, Payment Records, Payment Plans, Transactions page en rawh.
        2. Member payment status leh finance records check rawh.
        3. Own Payments-ah i fee/fund pe ve thei.
        4. Approve, reject, edit, delete, CSV export, settings te i role tan available lo a ni.

        Official finance action ngai chuan President, Secretary, Treasurer, emaw Finance Secretary contact rawh.
      ANSWER
    else
      <<~ANSWER.strip
        Finance page i role tan view-only angin a awm thei.

        I tih theih:

        1. Payments, Payment Records, Payment Plans, Transactions page en rawh.
        2. Member payment status leh finance records check rawh.
        3. Export CSV button a lang loh chuan i role-in export permission a nei lo tihna a ni.

        Approve/Reject tih chu President, Secretary, Treasurer, Finance Secretary tan chauh a ni.
      ANSWER
    end
  end

  def non_admin_answer
    <<~ANSWER.strip
      He action hi i role tan available lo a ni.

      I account-in view-only emaw member access emaw a neih chuan approve, edit, delete, settings, user roles tih te a lang lo ang.

      Official action ngai a nih chuan President, Secretary, Treasurer, Finance Secretary, emaw relevant Office Bearer contact rawh.
    ANSWER
  end

  def reports_answer
    if user.report_viewer?
      export_text = if user.advisory_viewer?
        "I role hi view-only/report viewer a ni. CSV export chu security avangin a lang lo ang."
      elsif user.super_admin? || user.finance_admin? || user.welfare_manager? || user.content_admin?
        "I role-in a phal chuan CSV export button a lang ang."
      else
        "CSV export chu role permission a zirin a lang ang."
      end

      <<~ANSWER.strip
        Reports hman dan:

        1. Reports page-ah lut rawh.
        2. Finance, Members, Events, Welfare reports chu i role-in a phal chin chauh a lang ang.
        3. Card leh chart te hmangin summary en rawh.
        4. #{export_text}

        Confidential data chu portal pawnah share suh.
      ANSWER
    else
      "Reports page hi i role tan available lo a ni. Report data mamawh chuan Office Bearer contact rawh."
    end
  end

  def settings_answer
    if user.super_admin?
      <<~ANSWER.strip
        Settings/Super Admin control hman dan:

        1. Settings page-ah lut rawh.
        2. General Settings-ah portal name, notice, maintenance setting te check/update theih a ni.
        3. User Roles-ah user role assign/change/deactivate theih a ni.
        4. Audit Logs-ah important activity records en theih a ni.
        5. Permissions page-ah role permission summary en theih a ni.

        Live portal-ah President/Secretary super admin account pakhat tal active reng tur a tha.
      ANSWER
    else
      "Settings, User Roles, Audit Logs, Permissions hi President leh Secretary super admin tan chauh a ni. I role tan a lang loh chuan expected behavior a ni."
    end
  end

  def notification_answer
    <<~ANSWER.strip
      Notification hman dan:

      1. Header-a bell icon click rawh.
      2. Notification list-ah unread/read status i hmu ang.
      3. Payment approved/rejected, welfare update, announcement, event update ang chi notification-ah a lo lang thei.
      4. Mark as read emaw mark all as read emaw hmangin clean theih a ni.

      Sign out hnuah notification badge a lang lo tur a ni.
    ANSWER
  end

  def account_answer
    <<~ANSWER.strip
      Sign in emaw password reset harsatna i neih chuan heti hian kal rawh:

      1. Google account i hmang chuan Continue with Google click rawh.
      2. Email/password account i siam tawh chuan Sign in with email hmang rawh.
      3. Password i theihnghilh chuan Forgot your password? click la i registered email dah rawh.
      4. Inbox leh Spam/Junk folder check rawh; reset link chu email-a instruction angin open rawh.
      5. Link a lo kal loh chuan email spelling leh registered account a nih check la, Office Bearer contact rawh.
      6. Google sign in error a awm chuan local password guess suh; Office Bearer hnenah screenshot nen report rawh.

      Password, reset link leh verification code chu midang hnenah share suh.
    ANSWER
  end

  def general_answer
    if user.member?
      member_general_answer
    elsif user.super_admin?
      super_admin_general_answer
    elsif user.finance_admin?
      finance_admin_general_answer
    elsif user.assistant_secretary?
      assistant_secretary_general_answer
    elsif user.observer_office_bearer?
      observer_general_answer
    elsif user.executive_committee?
      executive_general_answer
    else
      member_general_answer
    end
  end

  def member_general_answer
    <<~ANSWER.strip
      Member dashboard-ah i hman theih thil pawimawh te:

      1. Payments: membership fee/fund thlang la, bank transfer vawi khat chauhin pay together rawh.
      2. Profile: full name, mobile number, address, family information update rawh.
      3. Welfare: private support request submit theih a ni.
      4. Events: published event en leh RSVP theih a ni.
      5. Notifications: payment/welfare/event update i hmu thei.

      I zawhna hi page hming nen ziak leh chuan ka step-by-step in ka chhang ang.
    ANSWER
  end

  def super_admin_general_answer
    <<~ANSWER.strip
      Super Admin tan portal hman dan:

      1. Dashboard-ah member, payment, welfare, minutes, events, letters summary en rawh.
      2. Payments/Payment Records-ah submitted transfers approve/reject rawh.
      3. Payment Plans-ah membership fee, chhiatni fund, donation, fundraiser plan manage rawh.
      4. Welfare, Minutes, Events, Letters module te manage rawh.
      5. Settings-ah General Settings, User Roles, Audit Logs, Permissions enkawl rawh.
      6. Reports-ah finance/member/event/welfare summary leh export options i role-in a phal chin hmang rawh.
      7. User role change hma chuan role responsibility leh audit impact check rawh.

      Security atan, paid confirmation leh role change chu record dik tak check hnuah chauh tih tur a ni.
    ANSWER
  end

  def finance_admin_general_answer
    <<~ANSWER.strip
      Finance Admin tan portal hman dan:

      1. Payments page-ah member payment status en rawh.
      2. Payment Records-ah pending verification records approve/reject rawh.
      3. Payment Plans-ah fee/fund plan manage rawh.
      4. Transactions-ah income/expense records enkawl rawh.
      5. Reports-ah finance report en/export rawh, i role-in a phal chuan.
      6. Same member + same plan + same year/period duplicate record siam loh turin existing record check rawh.

      Settings, User Roles, Audit Logs chu finance admin tan available lo a ni.
    ANSWER
  end

  def assistant_secretary_general_answer
    <<~ANSWER.strip
      Assistant Secretary tan portal hman dan:

      1. Welfare cases, Events, Minutes, Letters chu Secretary ang deuhin manage theih a ni.
      2. Payments chu own fee/fund pek nan i hmang ve thei.
      3. Payment approval chu President/Secretary/Treasurer/Finance Secretary permission a ngai.
      4. Settings/User Roles/Audit Logs chu President leh Secretary super admin tan chauh a ni.
      5. Confidential records chu portal pawnah share suh.
      6. Report/finance confidential data chu i role permission a zirin view-only emaw hidden emaw a ni thei.
    ANSWER
  end

  def observer_general_answer
    <<~ANSWER.strip
      Vice President/Journal Secretary tan portal hman dan:

      1. Office Bearer an nih avangin dashboard/sidebar-ah admin-style pages i hmu thei ang.
      2. Finance, Payment Records, Payment Plans, Transactions, Welfare, Minutes, Letters, Reports chu view-only angin a awm thei.
      3. Own Payments chu member ang bawkin pay together theih a ni.
      4. Edit, approve, reject, delete, CSV export, settings, user roles tih te chu i role tan a lang lo ang.
      5. Official action ngai chuan relevant manager contact rawh.

      Hei hi expected behavior a ni; permission a lo inang loh chuan security/confidentiality vang a ni.
    ANSWER
  end

  def executive_general_answer
    <<~ANSWER.strip
      Executive Committee member tan portal hman dan:

      1. Dashboard-ah announcements, payments, profile activity i hmu ang.
      2. Payments chu member ang bawkin pay together theih a ni.
      3. Minutes/Reports/Welfare records chu i role-in a phal chin view-only a ni.
      4. CSV export, approve, edit, delete, settings tih te chu security avangin a lang lo ang.
      5. Official action ngai chuan Office Bearer contact rawh.
      6. Member private data leh welfare confidential details chu i role-in a phal chin chauh i hmu ang.
    ANSWER
  end

  def outside_portal_answer
    <<~ANSWER.strip
      Ka ngaihdanah he zawhna hi MSJ Portal chhung functionality chungchang ni lo deuh a ni.

      Ka chhang theih ber chu portal hman dan, membership, payments, welfare, events, minutes, letters, profile, leh reports chungchang a ni.

      Official emaw portal pawn lam thil pawimawh emaw a nih chuan Office Bearer contact rawh.
    ANSWER
  end

  def blank_question_answer
    "Zawhna ziak rawh. Entirnan: “Membership fee engtin nge ka pek ang?”"
  end

  def includes_any?(text, *keywords)
    keywords.any? { |keyword| text.include?(keyword) }
  end

  def outside_portal_question?(text)
    return false if includes_any?(
      text,
      "msj", "portal", "payment", "fee", "fund", "bank", "transfer", "yuucho", "ゆうちょ",
      "profile", "address", "mobile", "postal", "welfare", "event", "rsvp", "minute",
      "meeting", "letter", "official", "report", "member", "login", "sign in", "password",
      "dashboard", "notification", "approve", "verify", "treasurer", "secretary",
      "setting", "role", "permission", "audit", "csv", "export", "google", "forgot"
    )

    includes_any?(
      text,
      "weather", "stock", "bitcoin", "recipe", "movie", "game", "history of",
      "programming", "code", "ruby", "rails", "homework", "translate this"
    )
  end

end
