require "rails_helper"

RSpec.describe JobScraperJob, type: :job do
  it "creates companies and job posts from scraper results without calling external API" do
    user = create_user!(email: "jsj@example.com")
    job_search = create_job_search!(user: user, timezone: "UTC", board_relevance: [], number_of_jobs: 2)

    posted_at = Time.current
    results = [
      { title: "Engineer", company_name: "Acme", url: "https://example.com/1", description: "d1", location: "Anywhere", remote: true, posted_at: posted_at },
      { title: "Engineer", company_name: "Acme", url: "https://example.com/1", description: "d1", location: "Anywhere", remote: true, posted_at: posted_at }, # dup
      { title: "Senior", company_name: "Beta", url: "https://example.com/2", description: "d2", location: "Anywhere", remote: false, posted_at: posted_at }
    ]

    scraper = instance_double(JobScraper, scrape: results)
    allow(JobScraper).to receive(:new).and_return(scraper)

    described_class.perform_now(job_search.id)

    expect(Company.where(name: "Acme")).to exist
    expect(Company.where(name: "Beta")).to exist
    expect(JobPost.where(job_search: job_search).count).to eq(2)
    expect(JobPost.where(website: "https://example.com/1").count).to eq(1)
  end

  it "re-raises errors from the scraper (so retries can happen)" do
    user = create_user!(email: "jsj_err@example.com")
    job_search = create_job_search!(user: user, timezone: "UTC", board_relevance: [], number_of_jobs: 1)

    scraper = instance_double(JobScraper)
    allow(JobScraper).to receive(:new).and_return(scraper)
    allow(scraper).to receive(:scrape).and_raise(StandardError, "boom")

    expect { described_class.perform_now(job_search.id) }.to raise_error(StandardError, "boom")
  end

  it "skips when JobSearch no longer exists" do
    allow(JobScraper).to receive(:new)

    described_class.perform_now(0)

    expect(JobScraper).not_to have_received(:new)
  end
end

