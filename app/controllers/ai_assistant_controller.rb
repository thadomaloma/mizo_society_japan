class AiAssistantController < ApplicationController
  before_action :authorize_ai_assistant

  def index
    @question = ""
    @answer = nil
    @suggested_questions = suggested_questions
  end

  def create
    @question = params[:question].to_s.strip
    @answer = MizoAiAssistant.call(user: current_user, question: @question)
    @suggested_questions = suggested_questions

    render :index, status: @question.blank? ? :unprocessable_content : :ok
  end

  private

  def authorize_ai_assistant
    authorize :ai_assistant, "#{action_name}?".to_sym
  end

  def suggested_questions
    MizoAiAssistant.suggested_questions(user: current_user)
  end
end
