require "rails_helper"

RSpec.describe JobSearch, type: :model do
  it "defaults timezone before validation" do
    user = create_user!(email: "tz@example.com")
    job_search = JobSearch.new(user: user, job_title: "Ruby", language_code: "en", board_relevance: [])

    Time.use_zone("UTC") do
      job_search.valid?
      expect(job_search.timezone).to eq("UTC")
    end
  end

  it "validates language_code format" do
    user = create_user!(email: "lang@example.com")
    job_search = JobSearch.new(user: user, job_title: "Ruby", language_code: "english", timezone: "UTC", board_relevance: [])
    expect(job_search).not_to be_valid
    expect(job_search.errors[:language_code]).to be_present
  end

  it "validates board_relevance entries are non-blank job board names" do
    user = create_user!(email: "br@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: "UTC",
      board_relevance: [ "Indeed", "LinkedIn" ]
    )
    expect(job_search).to be_valid

    long = "a" * (JobSearch::BOARD_RELEVANCE_ENTRY_MAX_LENGTH + 1)
    job_search.assign_attributes(board_relevance: [ "Indeed", long ])
    expect(job_search).not_to be_valid
    expect(job_search.errors[:board_relevance]).to be_present

    job_search.assign_attributes(board_relevance: [ "Indeed", "   " ])
    expect(job_search).not_to be_valid
    expect(job_search.errors[:board_relevance]).to be_present
  end

  it "updates number_of_jobs via update_number_of_jobs!" do
    user = create_user!(email: "cnt@example.com")
    job_search = create_job_search!(user: user, number_of_jobs: 0)
    company = create_company!(name: "Acme")
    create_job_post!(company: company, job_search: job_search, website: "https://example.com/one")

    job_search.update_number_of_jobs!
    expect(job_search.reload.number_of_jobs).to eq(1)
  end
end
