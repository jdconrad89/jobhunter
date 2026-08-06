# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::BuildSuggestionPrompt do
  it "includes job and resume context in the prompt" do
    user = create_user!
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(
      company: company,
      job_search: job_search,
      title: "Senior Ruby Engineer",
      description: "Looking for Ruby on Rails and PostgreSQL experience."
    )
    resume = create_resume!(
      user: user,
      extracted_text: "Built APIs with Ruby on Rails",
      extraction_status: :completed
    )

    prompt = described_class.call(resume: resume, job_post: job_post)

    expect(prompt[:system]).to include("valid JSON only")
    expect(prompt[:user]).to include("Senior Ruby Engineer")
    expect(prompt[:user]).to include("Built APIs with Ruby on Rails")
    expect(prompt[:user]).to include("Ruby on Rails")
  end
end
