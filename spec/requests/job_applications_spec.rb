require "rails_helper"

RSpec.describe "JobApplications", type: :request do
  it "renders index grouped by status" do
    user = create_user!(email: "ja_index@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/idx")
    JobApplication.create!(user: user, job_post: post_record, status: "applied", applied_at: Time.zone.parse("2026-01-15 12:00"))

    get job_applications_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("January 15, 2026")
  end

  it "creates an application for a job post" do
    user = create_user!(email: "ja_req@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/applyme")

    post job_post_job_applications_path(post_record)
    expect(response).to redirect_to(job_post_path(post_record))
    expect(user.job_applications.where(job_post: post_record)).to exist
  end

  it "updates status via JSON and rejects invalid status" do
    user = create_user!(email: "ja_json@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/app2")
    application = JobApplication.create!(user: user, job_post: post_record)

    patch job_application_path(application), params: { status: "interviewing" }, as: :json
    expect(response).to have_http_status(:success)
    expect(application.reload.status).to eq("interviewing")

    patch job_application_path(application), params: { status: "nope" }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates status via HTML and handles invalid status param" do
    user = create_user!(email: "ja_html@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/html")
    application = JobApplication.create!(user: user, job_post: post_record)

    patch job_application_path(application), params: { status: "rejected" }
    expect(response).to redirect_to(job_applications_path)
    expect(application.reload.status).to eq("rejected")

    patch job_application_path(application), params: { status: "bad" }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "sets ghosted via manual checkbox on HTML update" do
    user = create_user!(email: "ja_ghost@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/ghost")
    application = JobApplication.create!(user: user, job_post: post_record, status: "interviewing")

    patch job_application_path(application), params: {
      job_application: { status: "interviewing", contact_info: "", followed_up: false },
      mark_as_ghosted: "1"
    }

    expect(response).to redirect_to(job_applications_path)
    expect(application.reload.status).to eq("ghosted")

    patch job_application_path(application), params: {
      job_application: { status: "ghosted", contact_info: "", followed_up: false },
      mark_as_ghosted: "0"
    }

    expect(response).to redirect_to(job_applications_path)
    expect(application.reload.status).to eq("applied")
  end

  it "renders show and updates contact info + followed_up via HTML" do
    user = create_user!(email: "ja_show@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/show")
    application = JobApplication.create!(user: user, job_post: post_record)

    get job_application_path(application)
    expect(response).to have_http_status(:success)

    patch job_application_path(application), params: {
      job_application: {
        contact_info: "recruiter@example.com",
        followed_up: true
      }
    }

    expect(response).to redirect_to(job_applications_path)
    expect(application.reload.contact_info).to eq("recruiter@example.com")
    expect(application.followed_up).to eq(true)
  end

  it "renders edit and updates followed_up via JSON top-level params" do
    user = create_user!(email: "ja_edit@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/edit")
    application = JobApplication.create!(user: user, job_post: post_record)

    get edit_job_application_path(application)
    expect(response).to have_http_status(:success)

    patch job_application_path(application), params: { followed_up: true, contact_info: "hm@example.com" }, as: :json
    expect(response).to have_http_status(:success)
    expect(application.reload.followed_up).to eq(true)
    expect(application.contact_info).to eq("hm@example.com")
  end

  it "returns validation errors when update fails (HTML + JSON)" do
    user = create_user!(email: "ja_update_fail@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    post_record = create_job_post!(company: company, job_search: job_search, website: "https://example.com/fail")
    application = JobApplication.create!(user: user, job_post: post_record)

    patch job_application_path(application), params: { job_application: { status: "bad" } }
    expect(response).to redirect_to(job_applications_path)

    patch job_application_path(application), params: { job_application: { status: "bad" } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
