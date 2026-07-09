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
    base_questions = [
      "Membership fee engtin nge ka pek ang?",
      "Yuucho bank atangin transfer engtin nge ka tih ang?",
      "Bank dang atangin transfer engtin nge ka tih ang?",
      "Profile complete dan min hrilh rawh.",
      "Welfare support dil dan eng nge?",
      "Event RSVP engtin nge ka tih ang?"
    ]

    base_questions << "Payment approve dan min hrilh rawh." if current_user.finance_approver?
    base_questions << "Payment plans engtin nge ka manage ang?" if current_user.finance_viewer?
    base_questions << "Welfare case assign dan eng nge?" if current_user.welfare_manager?
    base_questions << "Meeting minutes siam dan min hrilh rawh." if current_user.minute_manager?
    base_questions << "Official letter siam dan min hrilh rawh." if current_user.event_manager?
    base_questions << "Reports export theih dan eng nge?" if current_user.report_viewer?
    if current_user.super_admin?
      base_questions << "User roles thlak dan min hrilh rawh."
      base_questions << "Audit logs khawi atanga en tur nge?"
    end

    base_questions
  end
end
