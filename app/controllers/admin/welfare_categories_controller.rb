module Admin
  class WelfareCategoriesController < ApplicationController
    before_action :set_welfare_category, only: [ :edit, :update, :destroy ]

    def index
      authorize WelfareCategory
      @welfare_categories = policy_scope(WelfareCategory).includes(:welfare_cases).ordered
    end

    def new
      @welfare_category = WelfareCategory.new(active: true)
      authorize @welfare_category
    end

    def create
      @welfare_category = WelfareCategory.new(welfare_category_params)
      authorize @welfare_category

      if @welfare_category.save
        redirect_to admin_welfare_categories_path, notice: "Welfare category was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @welfare_category
    end

    def update
      authorize @welfare_category

      if @welfare_category.update(welfare_category_params)
        redirect_to admin_welfare_categories_path, notice: "Welfare category was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @welfare_category
      @welfare_category.destroy

      if @welfare_category.destroyed?
        redirect_to admin_welfare_categories_path, notice: "Welfare category was deleted."
      else
        redirect_to admin_welfare_categories_path, alert: "This category is used by welfare cases and cannot be deleted."
      end
    end

    private

    def set_welfare_category
      @welfare_category = policy_scope(WelfareCategory).find(params[:id])
    end

    def welfare_category_params
      params.require(:welfare_category).permit(:name, :description, :active)
    end
  end
end
