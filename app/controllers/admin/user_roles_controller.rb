module Admin
  class UserRolesController < ApplicationController
    before_action :set_user, only: [ :edit, :update, :deactivate, :reactivate ]

    def index
      authorize :user_role
      @query = params[:query].to_s.strip
      @role = params[:role].to_s
      @users = filtered_users
      @role_options = role_options
    end

    def permissions
      authorize :user_role, :index?
      @permission_groups = permission_groups
    end

    def new
      authorize :user_role, :create?
      @user = User.new(role: :member)
      @role_options = role_options
    end

    def create
      authorize :user_role
      @user = User.new(create_user_params)
      @user.role = requested_role || :member
      @user.password = Devise.friendly_token[0, 32]
      @role_options = role_options

      if @user.save
        @user.send_reset_password_instructions
        AuditLogger.call(
          user: current_user,
          action: "user_created",
          auditable: @user,
          metadata: {
            user_name: @user.name,
            user_email: @user.email,
            role: @user.role
          },
          request: request
        )
        redirect_to admin_user_roles_path, notice: "User was added and password setup email was sent."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize :user_role, :update?
      @role_options = role_options
    end

    def update
      authorize :user_role
      attributes = update_user_params
      new_role = requested_role || @user.role

      if @user.active? && last_active_super_admin? && !User::SUPER_ADMIN_ROLES.include?(new_role)
        redirect_to admin_user_roles_path, alert: "President or Secretary access must remain assigned."
        return
      end

      previous_role = @user.role
      profile_changed = attributes.slice(:name, :email).to_h.any? { |attribute, value| @user.public_send(attribute) != value }
      role_changed = previous_role != new_role

      @user.assign_attributes(attributes)
      @user.role = new_role

      if @user.save
        sync_member_profile_name(attributes[:name])

        AuditLogger.call(
          user: current_user,
          action: "user_updated",
          auditable: @user,
          metadata: { user_name: @user.name, user_email: @user.email },
          request: request
        ) if profile_changed

        AuditLogger.call(
          user: current_user,
          action: "user_role_changed",
          auditable: @user,
          metadata: {
            user_name: @user.display_name,
            user_email: @user.email,
            previous_role: previous_role,
            new_role: @user.role
          },
          request: request
        ) if role_changed

        redirect_to admin_user_roles_path(role: params[:current_role], query: params[:query]),
          notice: "User details were updated."
      else
        @role_options = role_options
        render :edit, status: :unprocessable_entity
      end
    end

    def deactivate
      authorize :user_role, :deactivate?
      return redirect_to_user_roles_with_alert("You cannot deactivate your own account.") if @user == current_user
      return redirect_to_user_roles_with_alert("President or Secretary access must remain assigned.") if last_active_super_admin?

      @user.update!(active: false)
      audit_account_status_change("user_deactivated")
      redirect_to admin_user_roles_path, notice: "#{@user.display_name} was deactivated."
    end

    def reactivate
      authorize :user_role, :reactivate?

      @user.update!(active: true)
      audit_account_status_change("user_reactivated")
      redirect_to admin_user_roles_path, notice: "#{@user.display_name} was reactivated."
    end

    private

    def filtered_users
      scope = User.includes(:member_profile).order(:name, :email)
      scope = scope.where(role: @role) if User.roles.key?(@role)
      return scope if @query.blank?

      scope.left_outer_joins(:member_profile).where(
        "users.name ILIKE :query OR users.email ILIKE :query OR member_profiles.full_name ILIKE :query",
        query: "%#{@query}%"
      )
    end

    def role_options
      User.roles.keys.map { |role| [ User.role_label(role), role ] }
    end

    def update_user_params
      params.require(:user).permit(:name, :email)
    end

    def create_user_params
      params.require(:user).permit(:name, :email)
    end

    def requested_role
      role = params.dig(:user, :role).to_s
      User.roles.key?(role) ? role : nil
    end

    def sync_member_profile_name(name)
      return if name.blank? || @user.member_profile.blank?
      return if @user.member_profile.full_name == name

      @user.member_profile.update!(full_name: name)
    end

    def set_user
      @user = User.find(params[:id])
    end

    def last_active_super_admin?
      return false unless User::SUPER_ADMIN_ROLES.include?(@user.role)

      User.active.where(role: User::SUPER_ADMIN_ROLES).where.not(id: @user.id).none?
    end

    def redirect_to_user_roles_with_alert(message)
      redirect_to admin_user_roles_path, alert: message
    end

    def audit_account_status_change(action)
      AuditLogger.call(
        user: current_user,
        action: action,
        auditable: @user,
        metadata: { user_name: @user.display_name, user_email: @user.email, active: @user.active? },
        request: request
      )
    end

    def permission_groups
      [
        {
          name: "Super Admin",
          users: "President, Secretary",
          permissions: [
            "Full access",
            "Manage members",
            "Manage finance",
            "Manage announcements",
            "Manage events",
            "Manage documents",
            "Manage welfare",
            "Manage reports",
            "Manage settings",
            "Manage user roles",
            "View audit logs",
            "Create or remove admins"
          ],
          restrictions: []
        },
        {
          name: "Office Bearers",
          users: "President, Vice President, Secretary, Assistant Secretary, Treasurer, Finance Secretary, Journal Secretary",
          permissions: [ "View office-bearers-only documents", "View office-bearers-only events", "View office-bearers-only meeting minutes", "Pay membership fees and active fund plans" ],
          restrictions: [ "Vice President and Journal Secretary use view-only access outside their permitted actions" ]
        },
        {
          name: "Finance Admin",
          users: "Treasurer, Finance Secretary",
          permissions: [
            "View members",
            "Manage payments and payment plans",
            "Manage finance transactions",
            "Manage finance reports",
            "Export finance reports"
          ],
          restrictions: [ "Cannot change system settings", "Cannot change user roles", "Cannot view audit logs", "Cannot delete members" ]
        },
        {
          name: "Assistant Secretary",
          users: "Assistant Secretary",
          permissions: [ "Manage meeting minutes", "Manage welfare cases", "Manage events", "Manage official letters" ],
          restrictions: [ "Cannot manage finance", "Cannot manage settings", "Cannot change user roles", "Cannot view audit logs" ]
        },
        {
          name: "Executive Committee",
          users: "Executive Member",
          permissions: [ "View reports", "View members", "View announcements", "View events", "View welfare records" ],
          restrictions: [ "Cannot edit system data", "Cannot create, assign, resolve, or reject welfare cases" ]
        },
        {
          name: "Member",
          users: "Members",
          permissions: [
            "View own profile",
            "Update own profile",
            "Pay membership fees and active fund plans",
            "RSVP events",
            "Download public documents",
            "Submit welfare requests"
          ],
          restrictions: []
        }
      ]
    end
  end
end
