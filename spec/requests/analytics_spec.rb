require "rails_helper"

RSpec.describe "Analytics", type: :request do
  it "requires login" do
    get analytics_path
    expect(response).to redirect_to(login_path)
  end

  it "renders analytics for the signed-in user" do
    user = create_user!(email: "analytics_page@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    create_job_post!(
      company: company,
      job_search: job_search,
      website: "https://example.com/analytics",
      description: "3-5 years experience with Ruby on Rails. $120k - $160k"
    )

    get analytics_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Job Post Analytics")
    expect(response.body).to include("Experience requirements")
    expect(response.body).to include("Most requested skills")
    expect(response.body).to include("Salary distribution by experience")
  end
end
