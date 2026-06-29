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

  it "generates an api token and shows it once" do
    user = create_user!(email: "token_create@example.com")
    sign_in_as(user)

    expect {
      post api_token_path
    }.to change { user.reload.api_token_configured? }.from(false).to(true)

    expect(response).to redirect_to(api_token_path)
    follow_redirect!
    expect(response.body).to include("Bearer")
    expect(user.api_token_digest).to be_present
    expect(user.api_token_digest).not_to include("=") # digest, not raw token

    get api_token_path
    expect(response.body).not_to match(/value="[A-Za-z0-9_-]{20,}"/)
    expect(response.body).to include("only shown immediately after")
  end
end
