class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :ensure_active_account!, unless: :devise_controller?
  before_action :enforce_maintenance_mode, unless: :devise_controller?
  before_action :ensure_completed_profile!, if: :profile_completion_required?
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def after_sign_in_path_for(user)
    return setup_profile_path unless user.profile_complete?

    user.operations_team? ? admin_dashboard_path : root_path
  end

  def after_sign_up_path_for(user)
    user.profile_complete? ? root_path : setup_profile_path
  end

  private

  def user_not_authorized
    redirect_to root_path, alert: "You are not authorized to access that area."
  end

  def ensure_active_account!
    return unless current_user && !current_user.active?

    sign_out current_user
    redirect_to new_user_session_path, alert: "Your account has been deactivated."
  end

  def profile_completion_required?
    return false unless current_user
    return false if devise_controller?
    return false if controller_path == "profiles"
    return false if controller_path == "ai_assistant"
    return false if controller_path == "rails/health"

    !current_user.profile_complete?
  end

  def ensure_completed_profile!
    redirect_to setup_profile_path, alert: "I profile hi la famkim lo. Member information hi update rawh."
  end

  def enforce_maintenance_mode
    return unless AppSetting.enabled?(:maintenance_mode)
    return if current_user&.super_admin?
    return if controller_path == "rails/health"

    render template: "maintenance/show", layout: "maintenance", status: :service_unavailable
  end
end
