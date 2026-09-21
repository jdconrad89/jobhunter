require "rails_helper"

RSpec.describe JobSearch, type: :model do
  it "defaults timezone before validation" do
    user = create_user!(email: "tz@example.com")
    job_search = JobSearch.new(user: user, job_title: "Ruby", language_code: "en", board_relevance: [])

    Time.use_zone("UTC") do
      job_search.valid?
      expect(job_search.timezone).to eq(JobSearch::DEFAULT_TIMEZONE)
    end
  end

  it "defaults timezone to the current zone when it is a supported US timezone" do
    user = create_user!(email: "tz_us@example.com")
    job_search = JobSearch.new(user: user, job_title: "Ruby", language_code: "en", board_relevance: [])

    Time.use_zone("Pacific Time (US & Canada)") do
      job_search.valid?
      expect(job_search.timezone).to eq("Pacific Time (US & Canada)")
    end
  end

  it "only allows US timezones" do
    user = create_user!(email: "tz_invalid@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: "London",
      board_relevance: []
    )

    expect(job_search).not_to be_valid
    expect(job_search.errors[:timezone]).to be_present
  end

  it "validates language_code format" do
    user = create_user!(email: "lang@example.com")
    job_search = JobSearch.new(user: user, job_title: "Ruby", language_code: "english", timezone: JobSearch::DEFAULT_TIMEZONE, board_relevance: [])
    expect(job_search).not_to be_valid
    expect(job_search.errors[:language_code]).to be_present
  end

  it "validates board_relevance entries are non-blank job board names" do
    user = create_user!(email: "br@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: JobSearch::DEFAULT_TIMEZONE,
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
    job_search = create_job_search!(user: user)
    company = create_company!(name: "Acme")
    create_job_post!(company: company, job_search: job_search, website: "https://example.com/one")

    job_search.update_number_of_jobs!
    expect(job_search.reload.number_of_jobs).to eq(1)
  end

  it "identifies the manual job search container" do
    user = create_user!(email: "manual@example.com")
    manual = create_job_search!(user: user, job_title: JobSearch::MANUAL_JOB_SEARCH_TITLE)
    regular = create_job_search!(user: user, job_title: "Ruby Engineer")

    expect(manual).to be_manual
    expect(regular).not_to be_manual
  end

  it "requires runtime to land on a 15-minute increment" do
    user = create_user!(email: "runtime@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: JobSearch::DEFAULT_TIMEZONE,
      board_relevance: [],
      runtime: Time.zone.local(2000, 1, 1, 9, 10)
    )

    expect(job_search).not_to be_valid
    expect(job_search.errors[:runtime]).to be_present

    job_search.runtime = Time.zone.local(2000, 1, 1, 9, 15)
    expect(job_search).to be_valid
  end

  it "composes runtime from 12-hour form parts" do
    expect(JobSearch.compose_runtime(hour: "", minute: "", meridiem: "")).to be_nil
    expect(JobSearch.compose_runtime(hour: "9", minute: "", meridiem: "AM")).to eq(false)

    composed = JobSearch.compose_runtime(hour: "9", minute: "15", meridiem: "AM")
    expect(composed.hour).to eq(9)
    expect(composed.min).to eq(15)

    composed_pm = JobSearch.compose_runtime(hour: "12", minute: "0", meridiem: "PM")
    expect(composed_pm.hour).to eq(12)

    composed_midnight = JobSearch.compose_runtime(hour: "12", minute: "0", meridiem: "AM")
    expect(composed_midnight.hour).to eq(0)
  end

  it "applies runtime dropdown parts on validation" do
    user = create_user!(email: "parts@example.com")
    job_search = JobSearch.new(
      user: user,
      job_title: "Ruby",
      language_code: "en",
      timezone: JobSearch::DEFAULT_TIMEZONE,
      board_relevance: [],
      runtime_hour: "2",
      runtime_minute: "45",
      runtime_meridiem: "PM"
    )

    expect(job_search).to be_valid
    expect(job_search.runtime.hour).to eq(14)
    expect(job_search.runtime.min).to eq(45)
  end

  it "treats blank runtime as unscheduled" do
    user = create_user!(email: "norun@example.com")
    job_search = create_job_search!(user: user, timezone: JobSearch::DEFAULT_TIMEZONE)

    expect(job_search.due_at?(Time.utc(2026, 9, 21, 9, 15))).to eq(false)
  end

  it "matches due_at? using the search timezone and 15-minute slot" do
    user = create_user!(email: "due@example.com")
    job_search = create_job_search!(
      user: user,
      timezone: "Eastern Time (US & Canada)",
      runtime: Time.zone.local(2000, 1, 1, 9, 15)
    )

    # 13:15 UTC == 09:15 Eastern (EDT in September)
    on_slot = Time.utc(2026, 9, 21, 13, 15)
    slightly_late = Time.utc(2026, 9, 21, 13, 17)
    wrong_slot = Time.utc(2026, 9, 21, 13, 30)

    expect(job_search.due_at?(on_slot)).to eq(true)
    expect(job_search.due_at?(slightly_late)).to eq(true)
    expect(job_search.due_at?(wrong_slot)).to eq(false)
  end

  it "returns schedulable searches due for the current slot via due_for_run" do
    user = create_user!(email: "due_for@example.com")
    zone = ActiveSupport::TimeZone[JobSearch::DEFAULT_TIMEZONE]
    due = create_job_search!(
      user: user,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 9, 0)
    )
    create_job_search!(
      user: user,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 10, 0)
    )
    create_job_search!(
      user: user,
      job_title: JobSearch::MANUAL_JOB_SEARCH_TITLE,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 9, 0)
    )
    create_job_search!(user: user, timezone: JobSearch::DEFAULT_TIMEZONE) # no runtime

    results = JobSearch.due_for_run(zone.local(2026, 9, 21, 9, 0))
    expect(results).to eq([ due ])
  end
end
