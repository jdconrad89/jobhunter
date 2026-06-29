# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPosts::Analytics do
  def make_post(user:, description:, title: "Engineer", pay_min: nil, pay_max: nil, exp_min: nil, exp_max: nil)
    job_search = create_job_search!(user: user)
    company = create_company!(name: "Acme #{SecureRandom.hex(2)}")
    post = create_job_post!(
      company: company,
      job_search: job_search,
      title: title,
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

  describe ".call" do
    it "returns analytics scoped to the user's job posts" do
      user = create_user!(email: "analytics@example.com")
      other = create_user!(email: "other@example.com")

      make_post(
        user: user,
        description: "3-5 years experience. Ruby on Rails and React. $100k - $150k",
        pay_min: 100_000,
        pay_max: 150_000,
        exp_min: 3,
        exp_max: 5
      )
      make_post(
        user: other,
        description: "10+ years experience. Python and AWS. $200k - $250k",
        pay_min: 200_000,
        pay_max: 250_000,
        exp_min: 10,
        exp_max: 10
      )

      result = described_class.call(user: user)

      expect(result.total_posts).to eq(1)
      expect(result.posts_with_experience).to eq(1)
      expect(result.posts_with_salary).to eq(1)
      expect(result.salary_points.size).to eq(1)
      expect(result.top_skills.map { |row| row[:skill] }).to include("Ruby on Rails", "React")
      expect(result.experience_breakdown.find { |row| row[:label] == "4-6 yrs" }[:count]).to eq(1)
    end
  end

  describe ".salary_distribution_for" do
    it "counts postings whose experience and salary ranges overlap the selection" do
      points = [
        { exp_min: 3, exp_max: 5, pay_min: 100_000, pay_max: 125_000 },
        { exp_min: 8, exp_max: 10, pay_min: 180_000, pay_max: 220_000 }
      ]

      distribution = described_class.salary_distribution_for(
        points: points,
        experience_min: 3,
        experience_max: 6
      )

      expect(distribution[:matching_posts]).to eq(1)
      expect(distribution[:counts].compact.sum).to be >= 1
      expect(distribution[:labels]).to include("$100k-124k")
    end
  end

  describe ".ranges_overlap?" do
    it "detects overlapping numeric ranges" do
      expect(described_class.ranges_overlap?(2, 5, 4, 8)).to eq(true)
      expect(described_class.ranges_overlap?(2, 3, 4, 8)).to eq(false)
    end
  end
end
