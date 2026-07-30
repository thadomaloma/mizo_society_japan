class WelfareCasesController < ApplicationController
  before_action :set_welfare_case, only: [ :show, :edit, :update ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize WelfareCase
    @status = params[:status]
    welfare_scope = policy_scope(WelfareCase)
    @welfare_summary = {
      open: welfare_scope.open_cases.count,
      review: welfare_scope.where(status: [ :reviewing, :in_progress ]).count,
      resolved: welfare_scope.resolved.count
    }
    @welfare_cases = welfare_scope
      .includes(:welfare_category, :assigned_to)
      .by_status(@status)
      .latest
  end

  def show
    authorize @welfare_case
  end

  def new
    @welfare_case = current_user.welfare_cases.new(priority: :medium)
    authorize @welfare_case
  end

  def create
    @welfare_case = current_user.welfare_cases.new(welfare_case_params)
    authorize @welfare_case

    if save_welfare_case
      NotificationCreator.welfare_case_submitted(@welfare_case, actor: current_user)
      redirect_to welfare_case_path(@welfare_case), notice: "Welfare request was submitted confidentially."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @welfare_case
  end

  def update
    authorize @welfare_case

    if save_welfare_case
      redirect_to welfare_case_path(@welfare_case), notice: "Welfare request was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_welfare_case
    @welfare_case = policy_scope(WelfareCase)
      .includes(:welfare_category, :assigned_to, welfare_attachments: { file_attachment: :blob })
      .find(params[:id])
  end

  def set_form_collections
    @welfare_categories = WelfareCategory.active.ordered
  end

  def welfare_case_params
    params.require(:welfare_case).permit(:welfare_category_id, :title, :description, :priority)
  end

  def uploaded_files
    Array(params.dig(:welfare_case, :files)).compact_blank
  end

  def save_welfare_case
    WelfareCaseWithAttachmentsSaver.call(
      welfare_case: @welfare_case,
      attributes: welfare_case_params,
      files: uploaded_files,
      uploaded_by: current_user
    )
  end
end
