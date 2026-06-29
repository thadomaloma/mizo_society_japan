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

    if @member_profile.update(member_profile_params)
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

    if @member_profile.update(member_profile_params)
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
    params.require(:member_profile).permit(
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
      family_members_attributes: [ :id, :name, :relationship, :_destroy ]
    )
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
end
