class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :resume_recommendations_enabled?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def resume_recommendations_enabled?
    FeatureFlags.resume_recommendations_enabled?
  end

  def require_resume_recommendations!
    return if resume_recommendations_enabled?

    redirect_to root_path, alert: "Resume recommendations are not available."
  end

  def require_login
    unless current_user
      redirect_to login_path, alert: "You must be logged in to access this page."
    end
  end
end
