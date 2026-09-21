# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  include ActiveJob::TestHelper

  it "requests a reset for an existing email and sends mail" do
    user = create_user!(email: "reset@example.com")

    expect {
      post password_reset_path, params: { email: user.email }
    }.to have_enqueued_mail(UserMailer, :password_reset)

    expect(response).to redirect_to(login_path)
    follow_redirect!
    expect(response.body).to include("If that email is in our system")
  end

  it "does not reveal whether an unknown email exists" do
    expect {
      post password_reset_path, params: { email: "missing@example.com" }
    }.not_to have_enqueued_mail(UserMailer, :password_reset)

    expect(response).to redirect_to(login_path)
  end

  it "resets the password with a valid token and signs the user in" do
    user = create_user!(email: "reset_ok@example.com", password: "password")
    token = user.generate_token_for(:password_reset)

    get edit_password_reset_path(token: token)
    expect(response).to have_http_status(:success)

    patch password_reset_path(token: token), params: {
      user: { password: "newpassword", password_confirmation: "newpassword" }
    }

    expect(response).to redirect_to(dashboard_path)
    user.reload
    expect(user.authenticate("newpassword")).to be_truthy
    expect(User.find_by_token_for(:password_reset, token)).to be_nil
  end

  it "rejects expired or invalid tokens" do
    user = create_user!(email: "reset_expired@example.com")
    token = user.generate_token_for(:password_reset)

    travel 3.hours do
      get edit_password_reset_path(token: token)
      expect(response).to redirect_to(new_password_reset_path)
    end

    get edit_password_reset_path(token: "bogus")
    expect(response).to redirect_to(new_password_reset_path)
  end

  it "shows validation errors for weak passwords" do
    user = create_user!(email: "reset_weak@example.com")
    token = user.generate_token_for(:password_reset)

    patch password_reset_path(token: token), params: {
      user: { password: "short", password_confirmation: "short" }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.authenticate("password")).to be_truthy
  end
end
