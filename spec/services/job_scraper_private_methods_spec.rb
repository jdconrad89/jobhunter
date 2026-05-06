require "rails_helper"

RSpec.describe JobScraper do
  describe "private helpers" do
    it "builds request params with remote/location and next_page_token" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper(location: "NYC", remote: true))
      params = scraper.send(:request_params, next_page_token: "t1")

      expect(params[:engine]).to eq("google_jobs")
      expect(params[:q]).to eq("Ruby")
      expect(params[:hl]).to eq("en")
      expect(params[:location]).to eq("NYC")
      expect(params[:next_page_token]).to eq("t1")
      expect(params[:ltype]).to eq(1)
    end

    it "maps remote flag to ltype codes" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)
      expect(scraper.send(:get_remote_code, true)).to eq(1)
      expect(scraper.send(:get_remote_code, false)).to eq(0)
      expect(scraper.send(:get_remote_code, nil)).to be_nil
    end

    it "parses posted date strings" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)

      travel_to(Time.utc(2026, 3, 25, 12, 0, 0)) do
        expect(scraper.send(:parse_posted_date, "2 days ago").to_i).to eq(2.days.ago.to_i)
        expect(scraper.send(:parse_posted_date, "3 weeks ago").to_i).to eq(3.weeks.ago.to_i)
        expect(scraper.send(:parse_posted_date, "1 month ago").to_i).to eq(1.month.ago.to_i)
        expect(scraper.send(:parse_posted_date, "today").to_i).to eq(Time.current.to_i)
        expect(scraper.send(:parse_posted_date, "yesterday").to_i).to eq(1.day.ago.to_i)
        expect(scraper.send(:parse_posted_date, "unknown")).to be_within(2).of(Time.current)
      end
    end

    it "returns nil url when no apply options" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)
      expect(scraper.send(:get_url, { apply_options: nil })).to be_nil
    end

    it "strips utm params from url" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper)
      result = { apply_options: [{ title: "Direct", link: "https://example.com/apply?utm_source=x&foo=bar&utm_medium=y" }] }
      expect(scraper.send(:get_url, result)).to eq("https://example.com/apply?foo=bar")
    end

    it "sorts links by board relevance" do
      scraper = described_class.new(job_search: stub_job_search_for_job_scraper(board_relevance: ["Indeed", "LinkedIn"]))
      options = [
        { title: "LinkedIn", link: "https://li.example.com" },
        { title: "Indeed", link: "https://in.example.com" }
      ]
      sorted = scraper.send(:sort_links_by_relevance, options)
      expect(sorted.first[:title]).to eq("Indeed")
    end
  end
end

