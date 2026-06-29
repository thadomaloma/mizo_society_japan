class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: [ :show, :edit, :update, :destroy, :publish, :archive ]

  def index
    authorize Announcement
    @query = params[:query]
    @category = params[:category].presence
    @status = current_user.content_admin? ? params[:status].presence : nil

    @announcements = policy_scope(Announcement)
      .includes(:author)
      .search(@query)
      .by_category(@category)
      .by_status(@status)
      .latest
  end

  def show
    authorize @announcement
    @announcement.mark_as_read_by!(current_user)
  end

  def new
    @announcement = Announcement.new(category: :general)
    authorize @announcement
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.author = current_user
    authorize @announcement

    if @announcement.save
      AuditLogger.call(user: current_user, action: "announcement_created", auditable: @announcement, metadata: announcement_metadata, request: request)
      redirect_to @announcement, notice: "Announcement was saved as a draft."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @announcement
  end

  def update
    authorize @announcement

    if @announcement.update(announcement_params)
      AuditLogger.call(user: current_user, action: "announcement_updated", auditable: @announcement, metadata: announcement_metadata, request: request)
      redirect_to @announcement, notice: "Announcement was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    authorize @announcement, :publish?
    AnnouncementPublisher.call(@announcement, actor: current_user)
    redirect_to @announcement, notice: "Announcement was published."
  end

  def archive
    authorize @announcement, :archive?
    @announcement.update!(status: :archived)
    AuditLogger.call(user: current_user, action: "announcement_archived", auditable: @announcement, metadata: announcement_metadata, request: request)
    redirect_to @announcement, notice: "Announcement was archived."
  end

  def destroy
    authorize @announcement
    AuditLogger.call(user: current_user, action: "announcement_deleted", auditable: @announcement, metadata: announcement_metadata, request: request)
    @announcement.destroy
    redirect_to announcements_path, notice: "Announcement was deleted."
  end

  private

  def set_announcement
    @announcement = policy_scope(Announcement).includes(:author).find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:title, :body, :category, :pinned, :expires_at)
  end

  def announcement_metadata
    { title: @announcement.title, category: @announcement.category, status: @announcement.status, pinned: @announcement.pinned? }
  end
end
