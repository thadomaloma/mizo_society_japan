module Admin
  class MembershipPlansController < ApplicationController
    before_action :set_membership_plan, only: [ :show, :edit, :update, :destroy ]
    before_action :set_plan_type_options, only: [ :new, :create, :edit, :update ]

    def index
      authorize MembershipPlan
      @plan_type_id = params[:plan_type_id].presence
      @membership_plans = policy_scope(MembershipPlan)
        .includes(:membership_payments, :membership_plan_type)
        .by_plan_type(@plan_type_id)
        .latest
      @plan_type_options = MembershipPlanType.active.latest
    end

    def show
      authorize @membership_plan
    end

    def new
      @membership_plan = MembershipPlan.new(
        active: true,
        membership_plan_type: MembershipPlanType.membership.first
      )
      authorize @membership_plan
    end

    def create
      @membership_plan = MembershipPlan.new(membership_plan_params)
      authorize @membership_plan

      if @membership_plan.save
        provision_required_member_payments
        redirect_to admin_membership_plan_path(@membership_plan), notice: "Payment plan was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @membership_plan
    end

    def update
      authorize @membership_plan

      if @membership_plan.update(membership_plan_params)
        provision_required_member_payments
        redirect_to admin_membership_plan_path(@membership_plan), notice: "Payment plan was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @membership_plan
      @membership_plan.destroy

      if @membership_plan.destroyed?
        redirect_to admin_membership_plans_path, notice: "Payment plan was deleted."
      else
        redirect_to admin_membership_plans_path, alert: "This plan has payment records and cannot be deleted."
      end
    end

    private

    def set_membership_plan
      @membership_plan = MembershipPlan.find(params[:id])
    end

    def membership_plan_params
      params.require(:membership_plan).permit(:name, :amount, :billing_cycle, :membership_plan_type_id, :active, :required_for_members, :description)
    end

    def provision_required_member_payments
      RequiredMembershipPaymentProvisioner.call(membership_plan: @membership_plan) if @membership_plan.auto_provisionable?
    end

    def set_plan_type_options
      plan_types = MembershipPlanType.active
      if @membership_plan&.membership_plan_type_id.present?
        plan_types = plan_types.or(MembershipPlanType.where(id: @membership_plan.membership_plan_type_id))
      end

      @plan_type_options = plan_types.latest
    end
  end
end
