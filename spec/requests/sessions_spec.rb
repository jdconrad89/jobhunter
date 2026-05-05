require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "logs in with valid credentials" do
    user = create_user!(email: "login@example.com", password: "password")
    post login_path, params: { email: user.email, password: "password" }
    expect(response).to redirect_to(dashboard_path)
  end

  it "rejects invalid credentials" do
    create_user!(email: "bad@example.com", password: "password")
    post login_path, params: { email: "bad@example.com", password: "wrong" }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "logs out" do
    user = create_user!(email: "logout@example.com")
    sign_in_as(user)
    delete logout_path
    expect(response).to redirect_to(root_path)
  end
end

