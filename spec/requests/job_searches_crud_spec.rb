require "rails_helper"

RSpec.describe "JobSearches CRUD", type: :request do
  it "creates, updates, destroys, and triggers a job search" do
    user = create_user!(email: "jscrud@example.com")
    sign_in_as(user)

    post job_searches_path, params: { job_search: { job_title: "Ruby", location: "Anywhere", remote: true, language_code: "en", timezone: "UTC", board_relevance: [ "Indeed" ] } }
    expect(response).to redirect_to(dashboard_path)

    job_search = user.job_searches.order(created_at: :desc).first
    expect(job_search).to be_present

    patch job_search_path(job_search), params: { job_search: { job_title: "Ruby 2" } }
    expect(response).to redirect_to(dashboard_path)
    expect(job_search.reload.job_title).to eq("Ruby 2")

    expect {
      post trigger_job_search_path(job_search)
    }.to have_enqueued_job(JobScraperJob).with(job_search.id)
    expect(response).to redirect_to(dashboard_path)

    delete job_search_path(job_search)
    expect(response).to redirect_to(dashboard_path)
    expect(JobSearch.where(id: job_search.id)).not_to exist
  end

  it "does not trigger scraping for the manual job search" do
    user = create_user!(email: "jscrud_manual@example.com")
    sign_in_as(user)

    manual_search = create_job_search!(
      user: user,
      job_title: JobSearch::MANUAL_JOB_SEARCH_TITLE,
      timezone: "UTC",
      board_relevance: []
    )

    expect {
      post trigger_job_search_path(manual_search)
    }.not_to have_enqueued_job(JobScraperJob)

    expect(response).to redirect_to(dashboard_path)
    follow_redirect!
    expect(response.body).to include("Manual job entries cannot be scraped")
  end
end
