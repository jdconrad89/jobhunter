require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects to login when logged out" do
    get dashboard_path
    expect(response).to redirect_to(login_path)
  end

  it "renders successfully when logged in" do
    user = create_user!(email: "dash@example.com")
    sign_in_as(user)
    get dashboard_path
    expect(response).to have_http_status(:success)
  end

  it "limits recent applications and shows the count summary" do
    user = create_user!(email: "dash-limit@example.com")
    sign_in_as(user)
    company = Company.create!(name: "Acme")
    job_search = user.job_searches.create!(job_title: "Ruby", language_code: "en", timezone: "UTC")

    12.times do |i|
      post = JobPost.create!(
        job_search: job_search,
        company: company,
        title: "Role #{i}",
        website: "https://example.com/#{i}"
      )
      user.job_applications.create!(job_post: post, status: "applied", applied_at: i.days.ago)
    end

    get dashboard_path
    expect(response.body).to include("Showing 10 of 12 applications")
    expect(response.body.scan('<article class="dashboard-app-card"').size).to eq(10)

    get dashboard_path, params: { applications_limit: 5 }
    expect(response.body).to include("Showing 5 of 12 applications")
    expect(response.body.scan('<article class="dashboard-app-card"').size).to eq(5)
  end
end
