# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeSuggestionJob, type: :job, resume_recommendations: true do
  it "generates suggestions for the resume suggestion record" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search)
    resume = create_resume!(
      user: user,
      extracted_text: "Ruby developer",
      extraction_status: :completed
    )
    suggestion = ResumeSuggestion.create!(resume: resume, job_post: job_post, status: :pending)

    client = instance_double(Llm::Client, chat: { overall_match_score: 70 }.to_json)
    allow(Llm::Client).to receive(:new).and_return(client)

    described_class.perform_now(suggestion.id)

    suggestion.reload
    expect(suggestion.status).to eq("completed")
    expect(suggestion.suggestions["overall_match_score"]).to eq(70)
  end

  it "marks the suggestion failed when rate limit retries are exhausted" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search)
    resume = create_resume!(
      user: user,
      extracted_text: "Ruby developer",
      extraction_status: :completed
    )
    suggestion = ResumeSuggestion.create!(resume: resume, job_post: job_post, status: :pending)

    job = described_class.new(suggestion.id)
    job.mark_rate_limit_failed(Llm::Client::RateLimitError.new("OpenAI rate limit reached"))

    suggestion.reload
    expect(suggestion.status).to eq("failed")
    expect(suggestion.error_message).to include("rate limit")
  end
end
