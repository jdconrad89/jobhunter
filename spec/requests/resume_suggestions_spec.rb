# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ResumeSuggestions", type: :request, resume_recommendations: true do
  it "creates a pending suggestion and enqueues generation" do
    user = create_user!(email: "suggestions_create@example.com")
    sign_in_as(user)
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/suggest")
    resume = create_resume!(
      user: user,
      extracted_text: "Ruby on Rails developer",
      extraction_status: :completed
    )

    expect {
      post job_post_resume_suggestion_path(job_post), params: { resume_id: resume.id }
    }.to have_enqueued_job(ResumeSuggestionJob)

    suggestion = ResumeSuggestion.find_by!(resume: resume, job_post: job_post)
    expect(suggestion.status).to eq("pending")
    expect(response).to redirect_to(job_post_path(job_post, resume_id: resume.id))
  end

  it "blocks suggestion when resume text is not ready" do
    user = create_user!(email: "suggestions_not_ready@example.com")
    sign_in_as(user)
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/not-ready")
    resume = create_resume!(user: user, extraction_status: :pending)

    post job_post_resume_suggestion_path(job_post), params: { resume_id: resume.id }

    expect(response).to redirect_to(job_post_path(job_post))
    follow_redirect!
    expect(response.body).to include("Resume text is not ready yet")
  end

  it "returns suggestion status as JSON" do
    user = create_user!(email: "suggestions_show@example.com")
    sign_in_as(user)
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/suggest-json")
    resume = create_resume!(
      user: user,
      extracted_text: "Ruby on Rails developer",
      extraction_status: :completed
    )
    ResumeSuggestion.create!(
      resume: resume,
      job_post: job_post,
      status: :completed,
      suggestions: { overall_match_score: 80 }
    )

    get job_post_resume_suggestion_path(job_post, resume_id: resume.id, format: :json)

    expect(response).to have_http_status(:success)
    expect(response.parsed_body["status"]).to eq("completed")
    expect(response.parsed_body["suggestions"]["overall_match_score"]).to eq(80)
  end
end
