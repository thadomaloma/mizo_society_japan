module Admin
  class FinanceCategoriesController < ApplicationController
    before_action :set_finance_category, only: [ :show, :edit, :update, :destroy ]

    def index
      authorize FinanceCategory
      @category_type = params[:category_type]
      @finance_categories = policy_scope(FinanceCategory)
        .includes(:finance_transactions)
        .then { |scope| FinanceCategory.category_types.key?(@category_type.to_s) ? scope.where(category_type: @category_type) : scope }
        .latest
    end

    def show
      authorize @finance_category
    end

    def new
      @finance_category = FinanceCategory.new(active: true)
      authorize @finance_category
    end

    def create
      @finance_category = FinanceCategory.new(finance_category_params)
      authorize @finance_category

      if @finance_category.save
        redirect_to admin_finance_categories_path, notice: "Finance category was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @finance_category
    end

    def update
      authorize @finance_category

      if @finance_category.update(finance_category_params)
        redirect_to admin_finance_categories_path, notice: "Finance category was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @finance_category
      @finance_category.destroy

      if @finance_category.destroyed?
        redirect_to admin_finance_categories_path, notice: "Finance category was deleted."
      else
        redirect_to admin_finance_categories_path, alert: @finance_category.errors.full_messages.to_sentence
      end
    end

    private

    def set_finance_category
      @finance_category = FinanceCategory.find(params[:id])
    end

    def finance_category_params
      params.require(:finance_category).permit(:name, :category_type, :active)
    end
  end
end
