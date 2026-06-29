module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      @user = User.from_google_oauth2(request.env["omniauth.auth"])

      if @user.persisted?
        flash[:notice] = "Signed in with Google."
        sign_in_and_redirect @user, event: :authentication
      else
        session["devise.google_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    def failure
      redirect_to new_user_session_path, alert: "Google sign in was cancelled or failed."
    end
  end
end
