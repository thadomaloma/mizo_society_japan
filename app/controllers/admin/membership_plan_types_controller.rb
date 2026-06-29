module Admin
  class MembershipPlanTypesController < ApplicationController
    before_action :set_membership_plan_type, only: [ :edit, :update, :destroy ]

    def index
      authorize MembershipPlanType
      @membership_plan_types = policy_scope(MembershipPlanType).includes(:membership_plans).latest
    end

    def new
      @membership_plan_type = MembershipPlanType.new(active: true)
      authorize @membership_plan_type
    end

    def create
      @membership_plan_type = MembershipPlanType.new(membership_plan_type_params)
      authorize @membership_plan_type

      if @membership_plan_type.save
        redirect_to admin_membership_plan_types_path, notice: "Plan type was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @membership_plan_type
    end

    def update
      authorize @membership_plan_type

      if @membership_plan_type.update(membership_plan_type_params)
        redirect_to admin_membership_plan_types_path, notice: "Plan type was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @membership_plan_type
      if @membership_plan_type.default?
        redirect_to admin_membership_plan_types_path, alert: "Default plan types cannot be deleted."
        return
      end

      @membership_plan_type.destroy

      if @membership_plan_type.destroyed?
        redirect_to admin_membership_plan_types_path, notice: "Plan type was deleted."
      else
        redirect_to admin_membership_plan_types_path, alert: "This type is used by payment plans and cannot be deleted."
      end
    end

    private

    def set_membership_plan_type
      @membership_plan_type = policy_scope(MembershipPlanType).find(params[:id])
    end

    def membership_plan_type_params
      params.require(:membership_plan_type).permit(:name, :active)
    end
  end
end
