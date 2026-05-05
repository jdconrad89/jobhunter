require "rails_helper"

RSpec.describe "Users", type: :request do
  it "signs up and redirects to dashboard" do
    post signup_path, params: { user: { name: "A", email: "new@example.com", password: "password", password_confirmation: "password" } }
    expect(response).to redirect_to(dashboard_path)
    expect(User.find_by(email: "new@example.com")).to be_present
  end

  it "renders errors on invalid signup" do
    post signup_path, params: { user: { name: "", email: "bad", password: "x", password_confirmation: "y" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end

