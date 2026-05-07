require "rails_helper"

RSpec.describe JobScraper do
  describe "#scrape" do
    it "deduplicates results by title+company_name" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)

      page1 = {
        jobs_results: [
          {
            title: "Engineer",
            company_name: "Acme",
            company_website: nil,
            company_description: nil,
            apply_options: [ { title: "Direct", link: "https://example.com/apply?utm_source=x&foo=bar" } ],
            description: "Desc",
            location: "Anywhere",
            remote: true,
            posted_at: "today"
          },
          {
            title: "Engineer",
            company_name: "Acme",
            company_website: nil,
            company_description: nil,
            apply_options: [ { title: "Direct", link: "https://example.com/apply?utm_medium=y&foo=baz" } ],
            description: "Desc",
            location: "Anywhere",
            remote: true,
            posted_at: "today"
          }
        ],
        serpapi_pagination: { next_page_token: "t2" }
      }

      page2 = {
        jobs_results: [
          {
            title: "Senior Engineer",
            company_name: "Beta",
            company_website: nil,
            company_description: nil,
            apply_options: [ { title: "Direct", link: "https://example.com/apply2?utm_campaign=z&foo=bar" } ],
            description: "Desc2",
            location: "Anywhere",
            remote: false,
            posted_at: "yesterday"
          }
        ],
        serpapi_pagination: nil
      }

      allow(scraper).to receive(:serpapi_response).and_return(page1, page2)

      results = scraper.scrape
      expect(results.length).to eq(2)
      expect(results.map { |r| [ r[:title], r[:company_name] ] }).to contain_exactly([ "Engineer", "Acme" ], [ "Senior Engineer", "Beta" ])

      engineer = results.find { |r| r[:title] == "Engineer" }
      expect(engineer[:url]).to eq("https://example.com/apply?foo=bar")
    end

    it "stops when jobs_results is nil" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)
      allow(scraper).to receive(:serpapi_response).and_return({ jobs_results: nil })

      expect(scraper.scrape).to eq([])
    end
  end
end
