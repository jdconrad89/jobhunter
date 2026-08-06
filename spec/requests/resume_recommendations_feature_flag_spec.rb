# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resume recommendations feature flag", type: :request do
  it "hides resumes from navigation and redirects resume routes when disabled" do
    disable_resume_recommendations!
    user = create_user!(email: "flag_disabled@example.com")
    sign_in_as(user)

    get dashboard_path
    expect(response.body).not_to include('href="/resumes"')

    get resumes_path
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Resume recommendations are not available")
  end

  it "hides resume suggestions on job posts when disabled" do
    disable_resume_recommendations!
    user = create_user!(email: "flag_job_show@example.com")
    sign_in_as(user)
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/flag")

    get job_post_path(job_post)

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include("Resume Suggestions")
  end

  it "shows resumes nav and job suggestions when enabled", resume_recommendations: true do
    user = create_user!(email: "flag_enabled@example.com")
    sign_in_as(user)
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/flag-on")

    get dashboard_path
    expect(response.body).to include('href="/resumes"')

    get job_post_path(job_post)
    expect(response.body).to include("Resume Suggestions")
  end
end
