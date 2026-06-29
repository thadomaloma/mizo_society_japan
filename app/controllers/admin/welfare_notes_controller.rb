module Admin
  class WelfareNotesController < ApplicationController
    before_action :set_welfare_case
    before_action :set_welfare_note, only: [ :edit, :update, :destroy ]

    def create
      @welfare_note = @welfare_case.welfare_notes.new(welfare_note_params.merge(user: current_user))
      authorize @welfare_note

      if @welfare_note.save
        redirect_to admin_welfare_case_path(@welfare_case), notice: "Internal note was added."
      else
        redirect_to admin_welfare_case_path(@welfare_case), alert: @welfare_note.errors.full_messages.to_sentence
      end
    end

    def edit
      authorize @welfare_note
    end

    def update
      authorize @welfare_note

      if @welfare_note.update(welfare_note_params)
        redirect_to admin_welfare_case_path(@welfare_case), notice: "Internal note was updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @welfare_note
      @welfare_note.destroy

      redirect_to admin_welfare_case_path(@welfare_case), notice: "Internal note was deleted."
    end

    private

    def set_welfare_case
      @welfare_case = policy_scope(WelfareCase).find(params[:welfare_case_id])
    end

    def set_welfare_note
      @welfare_note = policy_scope(@welfare_case.welfare_notes).find(params[:id])
    end

    def welfare_note_params
      params.require(:welfare_note).permit(:body, :internal)
    end
  end
end
