# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPosts::AnalyticsSynopsis do
  def make_post(user:, description:, pay_min: nil, pay_max: nil, exp_min: nil, exp_max: nil)
    job_search = create_job_search!(user: user)
    company = create_company!(name: "Acme #{SecureRandom.hex(2)}")
    post = create_job_post!(
      company: company,
      job_search: job_search,
      title: "Engineer",
      website: "https://example.com/#{SecureRandom.hex(4)}",
      description: description,
      remote: true
    )
    post.update_columns(
      pay_range_min: pay_min,
      pay_range_max: pay_max,
      experience_years_min: exp_min,
      experience_years_max: exp_max
    )
    post
  end

  it "returns guidance when there are no posts" do
    user = create_user!(email: "synopsis_empty@example.com")
    analytics = JobPosts::Analytics.call(user: user)

    result = described_class.call(analytics)

    expect(result.paragraphs.length).to eq(1)
    expect(result.paragraphs.first).to include("Add job postings")
  end

  it "summarizes coverage, experience, skills, and salary trends" do
    user = create_user!(email: "synopsis_full@example.com")

    make_post(
      user: user,
      description: "3-5 years experience. Ruby on Rails and React. $120k - $160k",
      pay_min: 120_000,
      pay_max: 160_000,
      exp_min: 3,
      exp_max: 5
    )
    make_post(
      user: user,
      description: "4-6 years experience. Ruby on Rails and AWS. $130k - $170k",
      pay_min: 130_000,
      pay_max: 170_000,
      exp_min: 4,
      exp_max: 6
    )

    analytics = JobPosts::Analytics.call(user: user)
    result = described_class.call(analytics)

    expect(result.paragraphs.length).to be >= 3
    expect(result.paragraphs.join(" ")).to include("tracking 2 job postings")
    expect(result.paragraphs.join(" ")).to include("Ruby on Rails")
    expect(result.paragraphs.join(" ")).to include("experience")
  end
end
