class EventPhotosController < ApplicationController
  def destroy
    @event = policy_scope(Event).find(params[:event_id])
    authorize @event, :update?
    attachment = @event.photos.attachments.find(params[:id])
    filename = attachment.filename.to_s
    attachment.purge
    AuditLogger.call(
      user: current_user,
      action: "event_image_removed",
      auditable: @event,
      metadata: { title: @event.title, filename: filename },
      request: request
    )

    redirect_to edit_event_path(@event), notice: "Event image was removed."
  end
end
