# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::GenerateSuggestions do
  it "stores parsed suggestions from the LLM" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search)
    resume = create_resume!(
      user: user,
      extracted_text: "Built APIs with Ruby on Rails",
      extraction_status: :completed
    )
    suggestion = ResumeSuggestion.create!(resume: resume, job_post: job_post, status: :pending)

    llm_response = {
      summary_changes: [ "Lead with backend experience" ],
      skills_to_emphasize: [ "Ruby on Rails" ],
      skills_missing_or_weak: [ "Kubernetes" ],
      bullet_rewrites: [],
      keywords_to_add: [ "PostgreSQL" ],
      overall_match_score: 78
    }.to_json

    client = instance_double(Llm::Client, chat: llm_response)
    allow(Llm::Client).to receive(:new).and_return(client)

    result = described_class.call(suggestion: suggestion)

    expect(result.success?).to be(true)
    suggestion.reload
    expect(suggestion.status).to eq("completed")
    expect(suggestion.suggestions["overall_match_score"]).to eq(78)
    expect(suggestion.suggestions["skills_to_emphasize"]).to include("Ruby on Rails")
  end

  it "marks the suggestion as failed when the LLM errors" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search)
    resume = create_resume!(
      user: user,
      extracted_text: "Built APIs with Ruby on Rails",
      extraction_status: :completed
    )
    suggestion = ResumeSuggestion.create!(resume: resume, job_post: job_post, status: :pending)

    client = instance_double(Llm::Client)
    allow(Llm::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat).and_raise(Llm::Client::Error, "API key missing")

    result = described_class.call(suggestion: suggestion)

    expect(result.success?).to be(false)
    suggestion.reload
    expect(suggestion.status).to eq("failed")
    expect(suggestion.error_message).to eq("API key missing")
  end

  it "keeps the suggestion pending and re-raises rate limit errors for job retry" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search)
    resume = create_resume!(
      user: user,
      extracted_text: "Built APIs with Ruby on Rails",
      extraction_status: :completed
    )
    suggestion = ResumeSuggestion.create!(resume: resume, job_post: job_post, status: :pending)

    client = instance_double(Llm::Client)
    allow(Llm::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat).and_raise(Llm::Client::RateLimitError, "OpenAI rate limit reached")

    expect {
      described_class.call(suggestion: suggestion)
    }.to raise_error(Llm::Client::RateLimitError)

    suggestion.reload
    expect(suggestion.status).to eq("pending")
    expect(suggestion.error_message).to include("rate limit")
  end
end
