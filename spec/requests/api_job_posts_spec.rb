require "rails_helper"

RSpec.describe "Api::JobPosts", type: :request do
  it "returns json including company" do
    user = create_user!(email: "api@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!(name: "Acme")
    create_job_post!(company: company, job_search: job_search, website: "https://example.com/api")

    get api_job_posts_path
    expect(response).to have_http_status(:success)
    body = JSON.parse(response.body)
    expect(body).to be_a(Array)
    expect(body.first["company"]).to include("name" => "Acme")
  end
end

