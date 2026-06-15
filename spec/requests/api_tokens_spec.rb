require "rails_helper"

RSpec.describe "ApiTokens", type: :request do
  it "requires login" do
    get api_token_path
    expect(response).to redirect_to(login_path)
  end

  it "shows the token page with a generate form" do
    user = create_user!(email: "token_show@example.com")
    sign_in_as(user)

    get api_token_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Generate Token")
    expect(response.body).to include('action="/api_token"')
  end

  it "generates an api token" do
    user = create_user!(email: "token_create@example.com")
    sign_in_as(user)

    expect {
      post api_token_path
    }.to change { user.reload.api_token }.from(nil)

    expect(response).to redirect_to(api_token_path)
    expect(user.api_token).to be_present
  end
end
