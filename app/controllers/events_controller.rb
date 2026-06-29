class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :publish, :complete, :cancel, :rsvp, :withdraw_rsvp, :calendar ]
  before_action :set_event_category_options, only: [ :new, :create, :edit, :update ]

  def index
    authorize Event
    @query = params[:query]
    @timeframe = params[:timeframe].presence_in(%w[upcoming past all]) || "upcoming"
    @event_category_id = params[:event_category_id].presence
    @status = current_user.event_manager? ? params[:status].presence : nil
    @event_category_options = EventCategory.active.ordered
    @latest_announcements = policy_scope(Announcement).latest.limit(3)

    @events = policy_scope(Event).includes(:created_by, :event_category, cover_image_attachment: :blob).search(@query).by_category(@event_category_id).by_status(@status)
    @events = @events.public_send(@timeframe) unless @timeframe == "all"
    @events = @events.latest if @timeframe == "all"
  end

  def show
    authorize @event
    @registration = @event.event_registrations.find_by(user: current_user)
    @registrations = @event.event_registrations.going.includes(user: :member_profile).latest if policy(@event).manage_registrations?
  end

  def new
    @event = Event.new(event_date: Date.current, start_time_of_day: "10:00", registration_required: true, visibility: :members_only, event_category: @event_category_options.first)
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    @event.created_by = current_user
    authorize @event

    if @event.save
      AuditLogger.call(user: current_user, action: "event_created", auditable: @event, metadata: event_metadata, request: request)
      redirect_to @event, notice: "Event was saved as a draft."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    if @event.update(event_params)
      AuditLogger.call(user: current_user, action: "event_updated", auditable: @event, metadata: event_metadata, request: request)
      redirect_to @event, notice: "Event was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    AuditLogger.call(user: current_user, action: "event_deleted", auditable: @event, metadata: event_metadata, request: request)
    @event.destroy
    redirect_to events_path, notice: "Event was deleted."
  end

  def publish
    authorize @event, :publish?
    EventPublisher.call(@event, actor: current_user)
    redirect_to @event, notice: "Event was published."
  end

  def complete
    authorize @event, :complete?
    @event.update!(status: :completed)
    AuditLogger.call(user: current_user, action: "event_completed", auditable: @event, metadata: event_metadata, request: request)
    redirect_to @event, notice: "Event was marked completed."
  end

  def cancel
    authorize @event, :cancel?
    @event.update!(status: :cancelled)
    AuditLogger.call(user: current_user, action: "event_cancelled", auditable: @event, metadata: event_metadata, request: request)
    redirect_to @event, notice: "Event was cancelled."
  end

  def rsvp
    authorize @event, :rsvp?
    registration = @event.event_registrations.find_or_initialize_by(user: current_user)
    registration.assign_attributes(status: :going, note: params.dig(:event_registration, :note))
    registration.save!

    redirect_to @event, notice: "Your RSVP has been recorded."
  end

  def withdraw_rsvp
    authorize @event, :withdraw_rsvp?
    registration = @event.event_registrations.find_by!(user: current_user)
    registration.update!(status: :cancelled)
    AuditLogger.call(
      user: current_user,
      action: "event_rsvp_withdrawn",
      auditable: @event,
      metadata: event_metadata.merge(member_id: current_user.id),
      request: request
    )

    redirect_to @event, notice: "Your RSVP was withdrawn."
  end

  def calendar
    authorize @event, :show?
    filename = "#{@event.title.parameterize.presence || "msj-event"}.ics"
    send_data EventCalendarExporter.call(@event), filename: filename, type: "text/calendar; charset=utf-8", disposition: :attachment
  end

  private

  def set_event
    @event = policy_scope(Event).includes(:created_by, :event_category, photos_attachments: :blob, cover_image_attachment: :blob).find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title, :event_date, :start_time_of_day, :venue, :description, :event_category_id,
      :registration_required, :max_participants, :registration_deadline, :visibility,
      :cover_image, photos: []
    )
  end

  def event_metadata
    { title: @event.title, event_date: @event.event_date, venue: @event.venue, category: @event.event_category.name, status: @event.status }
  end

  def set_event_category_options
    categories = EventCategory.active
    if @event&.event_category_id.present?
      categories = categories.or(EventCategory.where(id: @event.event_category_id))
    end

    @event_category_options = categories.ordered
  end
end
