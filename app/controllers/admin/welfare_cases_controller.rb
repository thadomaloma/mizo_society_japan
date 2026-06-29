module Admin
  class WelfareCasesController < ApplicationController
    before_action :set_welfare_case, only: [ :show, :edit, :update, :destroy, :assign, :resolve, :reject ]
    before_action :set_form_collections, only: [ :index, :new, :create, :edit, :update, :show ]

    def index
      authorize WelfareCase
      @status = params[:status]
      @priority = params[:priority]
      @category_id = params[:category_id]
      @assigned_to_id = params[:assigned_to_id]
      @query = params[:query]
      @welfare_cases = policy_scope(WelfareCase)
        .includes(:welfare_category, :user, :assigned_to)
        .search(@query)
        .by_status(@status)
        .by_priority(@priority)
        .by_category(@category_id)
        .by_assigned_to(@assigned_to_id)
        .latest
    end

    def show
      authorize @welfare_case
      @welfare_note = @welfare_case.welfare_notes.new(internal: true)
      @welfare_notes = policy_scope(@welfare_case.welfare_notes).includes(:user).chronological
    end

    def new
      @welfare_case = WelfareCase.new(priority: :medium, status: :submitted, confidential: true)
      authorize @welfare_case, :admin_create?
    end

    def create
      @welfare_case = WelfareCase.new(welfare_case_params)
      authorize @welfare_case, :admin_create?

      if @welfare_case.save
        attach_uploaded_files(@welfare_case)
        NotificationCreator.welfare_case_submitted(@welfare_case, actor: current_user)
        AuditLogger.call(
          user: current_user,
          action: "welfare_case_created",
          auditable: @welfare_case,
          metadata: welfare_case_metadata(@welfare_case),
          request: request
        )
        redirect_to admin_welfare_case_path(@welfare_case), notice: "Welfare case was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @welfare_case
    end

    def update
      authorize @welfare_case
      previous_status = @welfare_case.status

      if @welfare_case.update(welfare_case_params)
        attach_uploaded_files(@welfare_case)
        NotificationCreator.welfare_case_updated(@welfare_case, actor: current_user) if previous_status != @welfare_case.status
        redirect_to admin_welfare_case_path(@welfare_case), notice: "Welfare case was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @welfare_case
      @welfare_case.destroy

      redirect_to admin_welfare_cases_path, notice: "Welfare case was deleted."
    end

    def assign
      authorize @welfare_case, :assign?
      assignee_id = params.require(:welfare_case).fetch(:assigned_to_id)
      if assignee_id.blank?
        @welfare_case.update!(assigned_to: nil)
        redirect_back fallback_location: admin_welfare_case_path(@welfare_case), notice: "Welfare case was unassigned."
        return
      end

      assignee = assignable_users.find(assignee_id)
      WelfareCaseAssigner.call(@welfare_case, assignee: assignee, actor: current_user)

      redirect_back fallback_location: admin_welfare_case_path(@welfare_case), notice: "Welfare case was assigned."
    end

    def resolve
      authorize @welfare_case, :resolve?
      WelfareCaseResolver.call(@welfare_case, actor: current_user)

      redirect_back fallback_location: admin_welfare_case_path(@welfare_case), notice: "Welfare case was resolved."
    end

    def reject
      authorize @welfare_case, :reject?
      @welfare_case.update!(status: :rejected)
      NotificationCreator.welfare_case_rejected(@welfare_case, actor: current_user)
      AuditLogger.call(
        user: current_user,
        action: "welfare_case_rejected",
        auditable: @welfare_case,
        metadata: welfare_case_metadata(@welfare_case),
        request: request
      )

      redirect_back fallback_location: admin_welfare_case_path(@welfare_case), notice: "Welfare case was rejected."
    end

    private

    def set_welfare_case
      @welfare_case = policy_scope(WelfareCase)
        .includes(:welfare_category, :user, :assigned_to, welfare_attachments: { file_attachment: :blob })
        .find(params[:id])
    end

    def set_form_collections
      @welfare_categories = WelfareCategory.active.ordered
      @assignable_users = assignable_users
      @members = User.includes(:member_profile).order(:name, :email)
    end

    def assignable_users
      User.active.where(role: User::WELFARE_CASE_ASSIGNEE_ROLES).order(:role, :name, :email)
    end

    def welfare_case_params
      permitted_attributes = [
        :welfare_category_id,
        :title,
        :description,
        :priority,
        :status,
        :assigned_to_id,
        :confidential
      ]
      permitted_attributes << :user_id if action_name == "create"

      params.require(:welfare_case).permit(permitted_attributes)
    end

    def welfare_case_metadata(welfare_case)
      {
        title: welfare_case.title,
        member_name: welfare_case.user&.display_name,
        category: welfare_case.welfare_category&.name,
        status: welfare_case.status,
        priority: welfare_case.priority
      }
    end

    def uploaded_files
      Array(params.dig(:welfare_case, :files)).compact_blank
    end

    def attach_uploaded_files(welfare_case)
      uploaded_files.each do |file|
        attachment = welfare_case.welfare_attachments.build(uploaded_by: current_user)
        attachment.file.attach(file)
        attachment.save!
      end
    end
  end
end
