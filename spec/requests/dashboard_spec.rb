require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects to login when logged out" do
    get dashboard_path
    expect(response).to redirect_to(login_path)
  end

  it "renders successfully when logged in" do
    user = create_user!(email: "dash@example.com")
    sign_in_as(user)
    get dashboard_path
    expect(response).to have_http_status(:success)
  end
end

