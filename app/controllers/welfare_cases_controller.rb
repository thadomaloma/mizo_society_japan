class WelfareCasesController < ApplicationController
  before_action :set_welfare_case, only: [ :show, :edit, :update ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize WelfareCase
    @status = params[:status]
    @welfare_cases = policy_scope(WelfareCase)
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

    if @welfare_case.save
      attach_uploaded_files(@welfare_case)
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

    if @welfare_case.update(welfare_case_params)
      attach_uploaded_files(@welfare_case)
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

  def attach_uploaded_files(welfare_case)
    uploaded_files.each do |file|
      attachment = welfare_case.welfare_attachments.build(uploaded_by: current_user)
      attachment.file.attach(file)
      attachment.save!
    end
  end
end
