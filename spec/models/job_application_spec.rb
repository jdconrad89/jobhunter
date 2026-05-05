require "rails_helper"

RSpec.describe JobApplication, type: :model do
  it "sets initial status/applied_at on create" do
    user = create_user!(email: "ja1@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/a")

    application = JobApplication.create!(user: user, job_post: job_post)
    expect(application.status).to eq("applied")
    expect(application.applied_at).to be_present
  end

  it "validates status inclusion" do
    user = create_user!(email: "ja2@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/b")

    application = JobApplication.new(user: user, job_post: job_post, status: "bad", applied_at: Time.current)
    expect(application).not_to be_valid
    expect(application.errors[:status]).to be_present
  end

  it "enforces uniqueness of job_post per user" do
    user = create_user!(email: "ja3@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/c")

    JobApplication.create!(user: user, job_post: job_post)
    dup = JobApplication.new(user: user, job_post: job_post)
    expect(dup).not_to be_valid
    expect(dup.errors[:job_post_id]).to be_present
  end

  it "auto-ghosts applications not updated in 2 weeks" do
    user = create_user!(email: "ja4@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/d")

    application = JobApplication.create!(user: user, job_post: job_post, status: "interviewing", applied_at: Time.current)
    application.update_column(:updated_at, 3.weeks.ago)
    application.update!(status: "interviewing")

    expect(application.reload.status).to eq("ghosted")
  end

  it "does not allow ghosted status if recently updated" do
    user = create_user!(email: "ja5@example.com")
    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/e")

    application = JobApplication.create!(user: user, job_post: job_post, status: "interviewing", applied_at: Time.current)
    application.update_column(:updated_at, 1.day.ago)
    application.status = "ghosted"

    expect(application).not_to be_valid
    expect(application.errors[:status]).to be_present
  end
end

