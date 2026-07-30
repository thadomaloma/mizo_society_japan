class NotificationCreator
  def self.announcement_published(announcement, actor:)
    new(
      recipients: active_recipients,
      actor: actor,
      notifiable: announcement,
      action: :announcement_published,
      title: announcement.title,
      body: announcement.body.to_s.truncate(180),
      sync_recipients: true
    ).call
  end

  def self.event_created(event, actor:)
    new(
      recipients: event_recipients(event),
      actor: actor,
      notifiable: event,
      action: :event_created,
      title: event.title,
      body: event.description.to_s.truncate(180),
      sync_recipients: true
    ).call
  end

  def self.document_uploaded(document, actor:)
    new(
      recipients: document_recipients(document),
      actor: actor,
      notifiable: document,
      action: :document_uploaded,
      title: document.title,
      body: document.description.to_s.truncate(180),
      sync_recipients: true
    ).call
  end

  def self.meeting_minute_published(meeting_minute, actor:)
    new(
      recipients: meeting_minute_recipients,
      actor: actor,
      notifiable: meeting_minute,
      action: :meeting_minute_published,
      title: meeting_minute.title,
      body: meeting_minute.summary.to_s.truncate(180),
      sync_recipients: true
    ).call
  end

  def self.payment_submitted(payment, actor:)
    new(
      recipients: finance_recipients,
      actor: actor,
      notifiable: payment,
      action: :payment_submitted,
      title: "Payment pending verification",
      body: "#{payment.user.display_name} submitted #{payment.membership_plan.name} for #{payment.beneficiary_label}, amount #{payment.transfer_amount || payment.amount}."
    ).call
  end

  def self.payment_approved(payment, actor:)
    new(
      recipients: [ payment.user ],
      actor: actor,
      notifiable: payment,
      action: :payment_approved,
      title: "Payment approved",
      body: "#{payment.membership_plan.name} for #{payment.beneficiary_label} has been verified and marked paid."
    ).call
  end

  def self.welfare_case_submitted(welfare_case, actor:)
    new(
      recipients: welfare_recipients,
      actor: actor,
      notifiable: welfare_case,
      action: :welfare_case_submitted,
      title: welfare_case.title,
      body: welfare_case.description.to_s.truncate(180)
    ).call
  end

  def self.welfare_case_assigned(welfare_case, actor:)
    return if welfare_case.assigned_to.blank?

    new(
      recipients: [ welfare_case.assigned_to ],
      actor: actor,
      notifiable: welfare_case,
      action: :welfare_case_assigned,
      title: welfare_case.title,
      body: "A welfare case has been assigned to you."
    ).call
  end

  def self.welfare_case_updated(welfare_case, actor:)
    new(
      recipients: [ welfare_case.user ],
      actor: actor,
      notifiable: welfare_case,
      action: :welfare_case_updated,
      title: welfare_case.title,
      body: "Your welfare request status is now #{welfare_case.status.humanize.downcase}."
    ).call
  end

  def self.welfare_case_resolved(welfare_case, actor:)
    new(
      recipients: [ welfare_case.user ],
      actor: actor,
      notifiable: welfare_case,
      action: :welfare_case_resolved,
      title: welfare_case.title,
      body: "Your welfare request has been resolved."
    ).call
  end

  def self.welfare_case_rejected(welfare_case, actor:)
    new(
      recipients: [ welfare_case.user ],
      actor: actor,
      notifiable: welfare_case,
      action: :welfare_case_rejected,
      title: welfare_case.title,
      body: "Your welfare request has been rejected."
    ).call
  end

  def self.create_for_recipients(recipients:, actor:, notifiable:, action:, title:, body: nil)
    new(
      recipients: recipients,
      actor: actor,
      notifiable: notifiable,
      action: action,
      title: title,
      body: body
    ).call
  end

  def self.announcement_recipients
    active_recipients
  end

  def self.active_recipients
    User.active
      .left_outer_joins(:member_profile)
      .where("member_profiles.id IS NULL OR member_profiles.status = ?", MemberProfile.statuses[:active])
      .distinct
  end

  def self.event_recipients(event)
    recipients_for_visibility(event.visibility)
  end

  def self.document_recipients(document)
    recipients_for_visibility(document.visibility)
  end

  def self.meeting_minute_recipients
    active_recipients.where(role: User::OFFICE_BEARER_ROLES + User::ADVISORY_VIEWER_ROLES)
  end

  def self.recipients_for_visibility(visibility)
    case visibility.to_s
    when "public_access", "public_event", "members_only"
      active_recipients
    when "office_bearers_only"
      active_recipients.where(role: User::OFFICE_BEARER_ROLES)
    when "executive_committee_only"
      active_recipients.where(role: User::OFFICE_BEARER_ROLES + User::EXECUTIVE_ROLES)
    when "finance_only"
      active_recipients.where(role: User::FINANCE_ROLES)
    else
      User.none
    end
  end

  def self.welfare_recipients
    active_recipients.where(role: User::WELFARE_MANAGER_ROLES)
  end

  def self.finance_recipients
    active_recipients.where(role: User::FINANCE_ROLES)
  end

  def initialize(recipients:, actor:, notifiable:, action:, title:, body: nil, sync_recipients: false)
    @recipients = recipients
    @actor = actor
    @notifiable = notifiable
    @action = action
    @title = title
    @body = body
    @sync_recipients = sync_recipients
  end

  def call
    recipient_list = recipients.to_a.compact.uniq
    remove_notifications_for_other_recipients(recipient_list) if sync_recipients

    recipient_list.each do |recipient|
      create_notification(recipient)
    end
  end

  private

  attr_reader :recipients, :actor, :notifiable, :action, :title, :body, :sync_recipients

  def create_notification(recipient)
    notification = Notification.find_or_initialize_by(
      recipient: recipient,
      action: action,
      notifiable: notifiable
    )
    notification.assign_attributes(actor: actor, title: title, body: body)
    notification.save! if notification.new_record? || notification.changed?
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def remove_notifications_for_other_recipients(recipient_list)
    existing = Notification.where(action: action, notifiable: notifiable)
    recipient_ids = recipient_list.map(&:id)
    existing = existing.where.not(recipient_id: recipient_ids) if recipient_ids.any?
    existing.destroy_all
  end
end
