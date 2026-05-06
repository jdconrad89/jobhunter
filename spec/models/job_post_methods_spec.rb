require "rails_helper"

RSpec.describe JobPost, type: :model do
  def make_post(description:, title: "Engineer")
    user = create_user!(email: "#{SecureRandom.hex(4)}@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!(name: "Acme")
    create_job_post!(company: company, job_search: job_search, title: title, website: "https://example.com/#{SecureRandom.hex(4)}", description: description, remote: true)
  end

  describe "#extract_pay_range / #parse_pay_range_numbers" do
    it "extracts and parses $120k-$160k" do
      post = make_post(description: "Compensation: $120k - $160k per year")
      expect(post.extract_pay_range).to match(/\$120k\s*-\s*\$160k/i)
      expect(post.parse_pay_range_numbers).to eq([ 120_000, 160_000 ])
    end

    it "returns nil when description blank" do
      post = make_post(description: "")
      expect(post.extract_pay_range).to be_nil
      expect(post.parse_pay_range_numbers).to be_nil
    end
  end

  describe "#extract_experience_requirement / #parse_experience_years" do
    it "extracts range experience and parses years" do
      post = make_post(description: "Requirements: 3-5 years experience with Rails")
      expect(post.extract_experience_requirement).to eq("3-5 years")
      expect(post.parse_experience_years).to eq([ 3, 5 ])
    end

    it "extracts single experience and parses years" do
      post = make_post(description: "Minimum 4 years of experience")
      expect(post.extract_experience_requirement).to eq("4+ years")
      expect(post.parse_experience_years).to eq([ 4, 4 ])
    end

    it "extracts word-based experience" do
      post = make_post(description: "At least three years experience")
      expect(post.extract_experience_requirement).to eq("3+ years")
    end
  end

  describe "#contract?" do
    it "detects contract in title/description" do
      post = make_post(description: "This is a contract position", title: "Ruby Engineer")
      expect(post.contract?).to eq(true)
    end

    it "returns false when no text" do
      post = make_post(description: "", title: "Engineer")
      post.update_columns(title: nil, description: nil)
      expect(post.contract?).to eq(false)
    end
  end

  describe "#extracted_skills" do
    it "extracts known skills" do
      post = make_post(description: "We use Ruby on Rails, React, and AWS.", title: "Rails + React")
      expect(post.extracted_skills).to include("Ruby on Rails", "React", "AWS")
    end
  end

  describe "#suggested_jobs" do
    it "returns ranked suggestions based on skill overlap" do
      user = create_user!(email: "sj@example.com")
      job_search = create_job_search!(user: user)
      company = create_company!(name: "Acme")

      base = create_job_post!(company: company, job_search: job_search, title: "Base", website: "https://example.com/base", description: "Ruby on Rails React AWS", remote: true)
      best = create_job_post!(company: company, job_search: job_search, title: "Best", website: "https://example.com/best", description: "Ruby on Rails React AWS Docker", remote: true)
      ok = create_job_post!(company: company, job_search: job_search, title: "Ok", website: "https://example.com/ok", description: "Ruby on Rails React", remote: true)
      _none = create_job_post!(company: company, job_search: job_search, title: "None", website: "https://example.com/none", description: "Elixir Phoenix", remote: true)

      suggestions = base.suggested_jobs(limit: 2, candidate_pool: 10)
      expect(suggestions.map(&:first).map(&:id)).to eq([ best.id, ok.id ])
      expect(suggestions.first.last).to include("Ruby on Rails", "React", "AWS")
    end
  end

  describe "job_post_description_with_highlighted_pay helper" do
    it "wraps extracted pay range in highlight span" do
      post = make_post(description: "Pay range is $120,000 - $160,000 annually.\nGreat team.")
      html = ApplicationController.helpers.job_post_description_with_highlighted_pay(post)
      expect(html).to include("pay-range-highlight")
      expect(html).to include("$120,000 - $160,000")
    end

    it "returns empty string when description blank" do
      post = make_post(description: "")
      expect(ApplicationController.helpers.job_post_description_with_highlighted_pay(post)).to eq("")
    end
  end
end
