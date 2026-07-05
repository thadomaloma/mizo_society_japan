class NotificationsController < ApplicationController
  def index
    authorize Notification
    @notifications = policy_scope(Notification).includes(:actor, :notifiable).latest
  end

  def mark_as_read
    @notification = policy_scope(Notification).find(params[:id])
    authorize @notification, :mark_as_read?
    @notification.mark_as_read!

    redirect_back fallback_location: notifications_path, notice: "Notification marked as read."
  end

  def mark_all_as_read
    authorize Notification, :mark_all_as_read?
    policy_scope(Notification).unread.update_all(read_at: Time.current, updated_at: Time.current)
    Rails.cache.delete(current_user.notification_count_cache_key)

    redirect_back fallback_location: notifications_path, notice: "Notifications marked as read."
  end
end
