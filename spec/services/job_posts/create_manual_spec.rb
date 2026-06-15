require "rails_helper"

RSpec.describe JobPosts::CreateManual do
  it "creates a job post under the manual job search" do
    user = create_user!(email: "manual@example.com")

    result = described_class.call(
      user: user,
      attributes: {
        title: "Engineer",
        website: "https://example.com/job",
        company_name: "Acme",
        remote: true,
        description: "Build things"
      }
    )

    expect(result).to be_success
    expect(result.job_post.company.name).to eq("Acme")
    expect(result.job_post.job_search.job_title).to eq("Manual Job Entries")
    expect(result.job_post.job_search.user).to eq(user)
  end

  it "returns errors when company name is blank" do
    user = create_user!(email: "manual_blank@example.com")

    result = described_class.call(
      user: user,
      attributes: { title: "Engineer", website: "https://example.com/job", company_name: "" }
    )

    expect(result).not_to be_success
    expect(result.errors[:company]).to be_present
  end

  it "returns errors when job post is invalid" do
    user = create_user!(email: "manual_invalid@example.com")

    result = described_class.call(
      user: user,
      attributes: { title: "", website: "", company_name: "Acme" }
    )

    expect(result).not_to be_success
    expect(result.errors).to be_present
  end
end
