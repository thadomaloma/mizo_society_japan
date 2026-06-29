class MeetingMinutesController < ApplicationController
  before_action :set_meeting_minute, only: [ :show, :edit, :update, :destroy, :download, :export_pdf, :publish ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize MeetingMinute

    @query = params[:query]
    @year = params[:year]
    @meeting_minutes = policy_scope(MeetingMinute)
      .with_attached_file
      .with_attached_chairman_signature
      .with_attached_secretary_signature
      .includes(:uploaded_by, meeting_minute_attendances: :user)
      .search(@query)
      .by_year(@year)
      .latest
    year_sql = Arel.sql("EXTRACT(YEAR FROM meeting_date)::integer")
    @years = MeetingMinute.group(year_sql).order(Arel.sql("EXTRACT(YEAR FROM meeting_date)::integer DESC")).pluck(year_sql)
  end

  def show
    authorize @meeting_minute
  end

  def new
    @meeting_minute = MeetingMinute.new(meeting_date: Date.current, uploaded_by: current_user)
    authorize @meeting_minute
  end

  def create
    @meeting_minute = MeetingMinute.new(meeting_minute_params)
    @meeting_minute.uploaded_by = current_user
    @meeting_minute.status = :draft
    authorize @meeting_minute

    if @meeting_minute.save
      sync_checkbox_attendance
      audit_minute("meeting_minute_created")
      notice = publish_after_save_if_requested || "Meeting minute was saved as a draft."
      redirect_to meeting_minute_path(@meeting_minute), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @meeting_minute
  end

  def update
    authorize @meeting_minute

    if @meeting_minute.update(meeting_minute_params)
      sync_checkbox_attendance
      audit_minute("meeting_minute_updated")
      notice = publish_after_save_if_requested || "Meeting minute was updated."
      redirect_to meeting_minute_path(@meeting_minute), notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @meeting_minute
    metadata = minute_metadata
    @meeting_minute.destroy
    AuditLogger.call(user: current_user, action: "meeting_minute_deleted", metadata: metadata, request: request)

    redirect_to meeting_minutes_path, notice: "Meeting minute was deleted."
  end

  def download
    authorize @meeting_minute, :download?

    send_data @meeting_minute.file.download,
      filename: @meeting_minute.file.filename.to_s,
      type: @meeting_minute.file.content_type,
      disposition: "attachment"
  end

  def export_pdf
    authorize @meeting_minute, :show?

    send_data MeetingMinutePdfBuilder.call(@meeting_minute),
      filename: "#{@meeting_minute.title.parameterize.presence || "meeting-minute"}.pdf",
      type: "application/pdf",
      disposition: "attachment"
  end

  def publish
    authorize @meeting_minute, :publish?
    MeetingMinutePublisher.call(@meeting_minute, actor: current_user)

    redirect_to meeting_minute_path(@meeting_minute), notice: "Meeting minute was published."
  end

  private

  def set_meeting_minute
    @meeting_minute = policy_scope(MeetingMinute)
      .with_attached_file
      .with_attached_chairman_signature
      .with_attached_secretary_signature
      .includes(:uploaded_by, meeting_minute_attendances: :user)
      .find(params[:id])
  end

  def set_form_collections
    @attendance_users = attendance_users_for(User::OFFICE_BEARER_ROLES + User::EXECUTIVE_ROLES)
  end

  def attendance_users_for(roles)
    User.active.where(role: roles).includes(:member_profile).to_a.sort_by do |user|
      [ roles.index(user.role) || roles.length, user.display_name ]
    end
  end

  def meeting_minute_params
    permitted_params = params.require(:meeting_minute).permit(
      :title,
      :meeting_date,
      :meeting_time,
      :venue,
      :chairman,
      :minute_recorder,
      :opening_prayer,
      :welcome_speech,
      :previous_minutes_approval,
      :reports,
      :chairman_signature_name,
      :chairman_signature_title,
      :secretary_signature_name,
      :secretary_signature_title,
      :summary,
      :decisions,
      :adjournment,
      :file,
      :chairman_signature,
      :secretary_signature,
      present_attendee_ids: []
    )

    permitted_params.except(:present_attendee_ids)
  end

  def sync_checkbox_attendance
    @meeting_minute.sync_checkbox_attendance!(
      attendance_user_ids: @attendance_users.map(&:id),
      present_ids: params.dig(:meeting_minute, :present_attendee_ids)
    )
  end

  def publish_after_save_if_requested
    return unless params[:commit_action] == "publish"

    authorize @meeting_minute, :publish?
    MeetingMinutePublisher.call(@meeting_minute, actor: current_user)
    "Meeting minute was published."
  end

  def audit_minute(action)
    AuditLogger.call(
      user: current_user,
      action: action,
      auditable: @meeting_minute,
      metadata: minute_metadata,
      request: request
    )
  end

  def minute_metadata
    {
      title: @meeting_minute.title,
      meeting_date: @meeting_minute.meeting_date,
      meeting_time: @meeting_minute.meeting_time,
      status: @meeting_minute.status,
      chairman: @meeting_minute.chairman,
      minute_recorder: @meeting_minute.minute_recorder,
      adjournment: @meeting_minute.adjournment
    }
  end
end
