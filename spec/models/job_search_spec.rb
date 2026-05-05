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

  it "validates board_relevance is array of URLs" do
    user = create_user!(email: "br@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: "UTC",
      board_relevance: ["https://example.com", "notaurl"]
    )
    expect(job_search).not_to be_valid
    expect(job_search.errors[:board_relevance]).to be_present
  end

  it "computes runtime_in_timezone" do
    user = create_user!(email: "rt@example.com")
    job_search = JobSearch.create!(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: "Pacific Time (US & Canada)",
      runtime: Time.utc(2026, 3, 25, 12, 0, 0),
      board_relevance: []
    )

    expect(job_search.runtime_in_timezone).to be_present
  end

  it "computes next_run_time based on runtime and timezone" do
    user = create_user!(email: "nrt@example.com")
    job_search = JobSearch.create!(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: "UTC",
      runtime: Time.utc(2026, 3, 25, 10, 30, 0),
      board_relevance: []
    )

    travel_to(Time.utc(2026, 3, 25, 9, 0, 0)) do
      expect(job_search.next_run_time).to eq(Time.utc(2026, 3, 25, 10, 30, 0))
    end

    travel_to(Time.utc(2026, 3, 25, 11, 0, 0)) do
      expect(job_search.next_run_time).to eq(Time.utc(2026, 3, 26, 10, 30, 0))
    end
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

