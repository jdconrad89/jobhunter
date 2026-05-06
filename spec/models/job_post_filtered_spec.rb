require "rails_helper"

RSpec.describe JobPost, type: :model do
  describe ".filtered" do
    it "filters by company name (ILIKE)" do
      user = create_user!(email: "u1@example.com")
      job_search = create_job_search!(user: user)

      acme = create_company!(name: "Acme Corp")
      beta = create_company!(name: "Beta LLC")

      acme_post = create_job_post!(company: acme, job_search: job_search, title: "Engineer", website: "https://example.com/1", remote: true)
      _beta_post = create_job_post!(company: beta, job_search: job_search, title: "Engineer", website: "https://example.com/2", remote: true)

      results = JobPost.filtered(ActionController::Parameters.new(company: "acme"))
      expect(results).to include(acme_post)
      expect(results.map(&:company_id).uniq).to eq([ acme.id ])
    end

    it "filters by remote=true and remote=false" do
      user = create_user!(email: "u2@example.com")
      job_search = create_job_search!(user: user)
      company = create_company!(name: "Acme Corp")

      remote_post = create_job_post!(company: company, job_search: job_search, title: "Remote", website: "https://example.com/r", remote: true)
      onsite_post = create_job_post!(company: company, job_search: job_search, title: "Onsite", website: "https://example.com/o", remote: false)

      remote_results = JobPost.filtered(ActionController::Parameters.new(remote: "true"))
      expect(remote_results).to include(remote_post)
      expect(remote_results).not_to include(onsite_post)

      onsite_results = JobPost.filtered(ActionController::Parameters.new(remote: "false"))
      expect(onsite_results).to include(onsite_post)
      expect(onsite_results).not_to include(remote_post)
    end

    it "filters by pay_range and experience_range" do
      user = create_user!(email: "u3@example.com")
      job_search = create_job_search!(user: user)
      company = create_company!(name: "Acme Corp")

      low = create_job_post!(company: company, job_search: job_search, title: "Low", website: "https://example.com/low", description: "Salary: $50,000 - $60,000", remote: true)
      high = create_job_post!(company: company, job_search: job_search, title: "High", website: "https://example.com/high", description: "Salary: $180,000 - $220,000", remote: true)

      # ensure derived columns exist for filtering
      # use update_columns to avoid before_save callbacks recalculating these
      low.update_columns(pay_range_min: 50_000, pay_range_max: 60_000, experience_years_min: 2, experience_years_max: 3)
      high.update_columns(pay_range_min: 180_000, pay_range_max: 220_000, experience_years_min: 8, experience_years_max: 10)

      results = JobPost.filtered(ActionController::Parameters.new(pay_range: "100000_200000", experience_range: "5_8"))
      expect(results).not_to include(low)
      expect(results).to include(high)
    end

    it "orders newest job posts first" do
      user = create_user!(email: "u4@example.com")
      job_search = create_job_search!(user: user)
      company = create_company!(name: "Acme Corp")

      older = create_job_post!(company: company, job_search: job_search, title: "Older", website: "https://example.com/older")
      newer = create_job_post!(company: company, job_search: job_search, title: "Newer", website: "https://example.com/newer")

      older.update_columns(created_at: 2.days.ago)
      newer.update_columns(created_at: 1.day.ago)

      results = JobPost.filtered(ActionController::Parameters.new)
      expect(results.first(2)).to eq([ newer, older ])
    end
  end
end
