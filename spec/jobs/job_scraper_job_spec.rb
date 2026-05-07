require "rails_helper"

RSpec.describe JobScraperJob, type: :job do
  it "creates companies and job posts from scraper results without calling external API" do
    user = create_user!(email: "jsj@example.com")
    job_search = create_job_search!(user: user, timezone: "UTC", board_relevance: [])

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
    job_search = create_job_search!(user: user, timezone: "UTC", board_relevance: [])

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

  # TODO: If/when we transition away from wrapping this logic in a transaction make sure we remove this test
  it "rolls back the full import when persistence fails mid-batch" do
    user = create_user!(email: "jsj_tx@example.com")
    job_search = create_job_search!(user: user, timezone: "UTC", board_relevance: [])

    posted_at = Time.current
    results = [
      { title: "First", company_name: "TxCo", url: "https://example.com/tx1", description: "d1", location: "Anywhere", remote: true, posted_at: posted_at },
      { title: "Second", company_name: "TxCo", url: "https://example.com/tx2", description: "d2", location: "Anywhere", remote: false, posted_at: posted_at }
    ]

    scraper = instance_double(JobScraper, scrape: results)
    allow(JobScraper).to receive(:new).and_return(scraper)

    calls = 0
    allow(JobPost).to receive(:find_or_create_by!).and_wrap_original do |method, *args, **kwargs, &block|
      calls += 1
      raise StandardError, "simulated failure" if calls > 1

      method.call(*args, **kwargs, &block)
    end

    expect { described_class.perform_now(job_search.id) }.to raise_error(StandardError, "simulated failure")

    expect(JobPost.where(job_search: job_search).count).to eq(0)
    expect(Company.where(name: "TxCo")).not_to exist
  end
end
