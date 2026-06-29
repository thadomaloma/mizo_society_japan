module Admin
  class DocumentCategoriesController < ApplicationController
    before_action :set_document_category, only: [ :edit, :update, :destroy ]

    def index
      authorize DocumentCategory
      @document_categories = policy_scope(DocumentCategory).includes(:documents).ordered
    end

    def new
      @document_category = DocumentCategory.new(active: true, position: next_position)
      authorize @document_category
    end

    def create
      @document_category = DocumentCategory.new(document_category_params)
      authorize @document_category

      if @document_category.save
        redirect_to admin_document_categories_path, notice: "Letter category was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @document_category
    end

    def update
      authorize @document_category

      if @document_category.update(document_category_params)
        redirect_to admin_document_categories_path, notice: "Letter category was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @document_category
      @document_category.destroy

      if @document_category.destroyed?
        redirect_to admin_document_categories_path, notice: "Letter category was deleted."
      else
        redirect_to admin_document_categories_path, alert: "This category is used by letters and cannot be deleted."
      end
    end

    private

    def set_document_category
      @document_category = policy_scope(DocumentCategory).find(params[:id])
    end

    def document_category_params
      params.require(:document_category).permit(:name, :description, :active, :position)
    end

    def next_position
      DocumentCategory.maximum(:position).to_i + 1
    end
  end
end
