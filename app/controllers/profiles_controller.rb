class ProfilesController < ApplicationController
  before_action :set_member_profile

  def show
    authorize @member_profile
    redirect_to setup_profile_path unless @member_profile.persisted? && @member_profile.complete?
  end

  def setup
    authorize @member_profile, :setup?
  end

  def create_setup
    authorize @member_profile, :setup?
    new_profile = !@member_profile.persisted?

    result = update_member_profile_with_upload_handling(:setup)
    return if result == :upload_error

    if result
      MembershipPaymentProvisioner.call(user: current_user)
      AuditLogger.call(
        user: current_user,
        action: new_profile ? "member_created" : "member_updated",
        auditable: @member_profile,
        metadata: member_profile_metadata(@member_profile),
        request: request
      )
      redirect_to profile_destination_path, notice: "Profile completed."
    else
      render :setup, status: :unprocessable_entity
    end
  end

  def edit
    authorize @member_profile
  end

  def update
    authorize @member_profile

    result = update_member_profile_with_upload_handling(:edit)
    return if result == :upload_error

    if result
      MembershipPaymentProvisioner.call(user: current_user)
      AuditLogger.call(
        user: current_user,
        action: "member_updated",
        auditable: @member_profile,
        metadata: member_profile_metadata(@member_profile),
        request: request
      )
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_member_profile
    @member_profile = current_user.member_profile || current_user.build_member_profile(
      full_name: current_user.name.presence || current_user.email.to_s.split("@").first
    )
  end

  def member_profile_params
    permitted = params.require(:member_profile).permit(
      :avatar,
      :full_name,
      :mobile_number,
      :gender,
      :date_of_birth,
      :postal_code,
      :prefecture,
      :city,
      :address_line1,
      :address_line2,
      :father_name,
      :mother_name,
      :family_status,
      :spouse_name,
      family_members_attributes: [ :id, :name, :date_of_birth, :relationship, :_destroy ]
    )
    sanitize_family_member_ids(permitted)
  end

  def profile_destination_path
    current_user.operations_team? ? admin_dashboard_path : root_path
  end

  def member_profile_metadata(profile)
    {
      member_name: profile.full_name,
      membership_number: profile.membership_number,
      prefecture: profile.prefecture,
      city: profile.city,
      status: profile.status
    }
  end

  def update_member_profile_with_upload_handling(error_view)
    @member_profile.update(member_profile_params)
  rescue ActiveStorage::Error => error
    handle_avatar_upload_error(error, error_view)
  rescue StandardError => error
    raise unless avatar_upload_attempt? && storage_service_error?(error)

    handle_avatar_upload_error(error, error_view)
  end

  def handle_avatar_upload_error(error, error_view)
    Rails.logger.error(
      "Profile avatar upload failed for user_id=#{current_user.id}: #{error.class} - #{error.message}"
    )
    @member_profile.errors.add(:avatar, "could not be uploaded. Please try again or contact an administrator.")
    render error_view, status: :unprocessable_entity
    :upload_error
  end

  def avatar_upload_attempt?
    params.dig(:member_profile, :avatar).present?
  end

  def storage_service_error?(error)
    error_class = error.class.name
    error_class.start_with?("Aws::S3::Errors::") ||
      error_class.start_with?("Seahorse::Client::") ||
      error_class == "Errno::ECONNREFUSED" ||
      error_class == "SocketError"
  end

  def sanitize_family_member_ids(permitted)
    family_attributes = permitted[:family_members_attributes]
    return permitted if family_attributes.blank?

    valid_ids = @member_profile.family_members.pluck(:id).map(&:to_s)
    family_attributes.each_value do |attributes|
      next if attributes[:id].blank? || valid_ids.include?(attributes[:id].to_s)

      Rails.logger.warn(
        "Ignored stale family member id=#{attributes[:id]} for profile_id=#{@member_profile.id || 'new'}"
      )
      attributes.delete(:id)
    end

    permitted
  end
end
