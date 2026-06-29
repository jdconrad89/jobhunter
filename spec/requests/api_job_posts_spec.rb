require "rails_helper"

RSpec.describe "Api::JobPosts", type: :request do
  describe "GET /api/job_posts" do
    it "returns the authenticated user's job posts including company" do
      user = create_user!(email: "api@example.com")
      user.regenerate_api_token!
      other = create_user!(email: "api_other@example.com")

      job_search = create_job_search!(user: user)
      company = create_company!(name: "Acme")
      create_job_post!(company: company, job_search: job_search, website: "https://example.com/api")

      other_search = create_job_search!(user: other)
      other_company = create_company!(name: "OtherCo")
      create_job_post!(company: other_company, job_search: other_search, website: "https://example.com/other")

      get api_job_posts_path, headers: api_auth_headers(user)
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body).to be_a(Array)
      expect(body.length).to eq(1)
      expect(body.first["company"]).to include("name" => "Acme")
    end

    it "returns unauthorized without a token" do
      get api_job_posts_path
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
    end
  end

  describe "POST /api/job_posts" do
    it "creates a job post when authenticated" do
      user = create_user!(email: "api_create@example.com")
      user.regenerate_api_token!

      expect {
        post api_job_posts_path,
          params: {
            job_post: {
              title: "Senior Engineer",
              website: "https://example.com/api-create",
              company_name: "Acme",
              location: "Remote",
              remote: true,
              description: "Great role"
            }
          },
          headers: api_auth_headers(user),
          as: :json
      }.to change(JobPost, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Senior Engineer")
      expect(body["company"]).to include("name" => "Acme")
      expect(body["url"]).to include("/job_posts/")
    end

    it "returns unauthorized without a token" do
      post api_job_posts_path,
        params: { job_post: { title: "Engineer", website: "https://example.com/x", company_name: "Acme" } },
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
    end

    it "returns validation errors for invalid data" do
      user = create_user!(email: "api_invalid@example.com")
      user.regenerate_api_token!

      post api_job_posts_path,
        params: { job_post: { title: "", website: "", company_name: "Acme" } },
        headers: api_auth_headers(user),
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
end
