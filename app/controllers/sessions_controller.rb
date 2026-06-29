class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if current_user
  end

  def create
    user = User.find_by(email: session_params[:email])
    if user&.authenticate(session_params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully logged in!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Successfully logged out!"
  end

  private

  def session_params
    params.permit(:email, :password)
  end
end
