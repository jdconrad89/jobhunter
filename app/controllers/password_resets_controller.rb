# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :set_user_from_token, only: [ :edit, :update ]

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.where("LOWER(email) = ?", email).first

    if user
      raw_token = user.generate_token_for(:password_reset)
      UserMailer.password_reset(user, raw_token).deliver_later
    end

    # Same message whether or not the account exists.
    redirect_to login_path, notice: "If that email is in our system, you'll receive password reset instructions shortly."
  end

  def edit
  end

  def update
    if @user.update(password_params)
      reset_session
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Your password has been reset. You are now logged in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_from_token
    @token = params[:token].to_s
    @user = User.find_by_token_for(:password_reset, @token)

    return if @user

    redirect_to new_password_reset_path, alert: "That password reset link is invalid or has expired. Request a new one."
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
