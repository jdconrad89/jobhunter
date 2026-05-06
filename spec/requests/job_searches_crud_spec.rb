require "rails_helper"

RSpec.describe "JobSearches CRUD", type: :request do
  it "creates, updates, destroys, and triggers a job search" do
    user = create_user!(email: "jscrud@example.com")
    sign_in_as(user)

    post job_searches_path, params: { job_search: { job_title: "Ruby", location: "Anywhere", remote: true, language_code: "en", timezone: "UTC", board_relevance: ["Indeed"] } }
    expect(response).to redirect_to(dashboard_path)

    job_search = user.job_searches.order(created_at: :desc).first
    expect(job_search).to be_present

    patch job_search_path(job_search), params: { job_search: { job_title: "Ruby 2" } }
    expect(response).to redirect_to(dashboard_path)
    expect(job_search.reload.job_title).to eq("Ruby 2")

    expect {
      post trigger_job_search_path(job_search)
    }.to have_enqueued_job(JobScraperJob)
    expect(response).to redirect_to(dashboard_path)

    delete job_search_path(job_search)
    expect(response).to redirect_to(dashboard_path)
    expect(JobSearch.where(id: job_search.id)).not_to exist
  end
end

