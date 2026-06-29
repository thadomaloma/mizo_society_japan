module Admin
  class EventCategoriesController < ApplicationController
    before_action :set_event_category, only: [ :edit, :update, :destroy ]

    def index
      authorize EventCategory
      @event_categories = policy_scope(EventCategory).includes(:events).ordered
    end

    def new
      @event_category = EventCategory.new(active: true, position: next_position)
      authorize @event_category
    end

    def create
      @event_category = EventCategory.new(event_category_params)
      authorize @event_category

      if @event_category.save
        redirect_to admin_event_categories_path, notice: "Event category was created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @event_category
    end

    def update
      authorize @event_category

      if @event_category.update(event_category_params)
        redirect_to admin_event_categories_path, notice: "Event category was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @event_category
      @event_category.destroy

      if @event_category.destroyed?
        redirect_to admin_event_categories_path, notice: "Event category was deleted."
      else
        redirect_to admin_event_categories_path, alert: "This category is used by events and cannot be deleted."
      end
    end

    private

    def set_event_category
      @event_category = policy_scope(EventCategory).find(params[:id])
    end

    def event_category_params
      params.require(:event_category).permit(:name, :active, :position)
    end

    def next_position
      EventCategory.maximum(:position).to_i + 1
    end
  end
end
