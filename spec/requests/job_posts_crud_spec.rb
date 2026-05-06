require "rails_helper"

RSpec.describe "JobPosts CRUD", type: :request do
  it "renders new and creates a job post for the manual job search" do
    user = create_user!(email: "jp_crud@example.com")
    sign_in_as(user)

    get new_job_post_path
    expect(response).to have_http_status(:success)

    expect {
      post job_posts_path, params: { job_post: { title: "Engineer", website: "https://example.com/jp", company_name: "Acme", remote: true } }
    }.to change(JobPost, :count).by(1)

    job_post = JobPost.order(created_at: :desc).first
    expect(response).to redirect_to(job_post_path(job_post))
    expect(job_post.job_search.job_title).to eq("Manual Job Entries")
    expect(job_post.company.name).to eq("Acme")
  end

  it "shows validation errors when company name is blank" do
    user = create_user!(email: "jp_blank_company@example.com")
    sign_in_as(user)

    post job_posts_path, params: { job_post: { title: "Engineer", website: "https://example.com/jp2", company_name: "" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "shows validation errors when job post is invalid" do
    user = create_user!(email: "jp_invalid@example.com")
    sign_in_as(user)

    post job_posts_path, params: { job_post: { title: "", website: "", company_name: "Acme" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders show" do
    user = create_user!(email: "jp_show@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    job_post = create_job_post!(company: company, job_search: job_search, website: "https://example.com/show")

    get job_post_path(job_post)
    expect(response).to have_http_status(:success)
  end

  it "accepts per_page parameter and defaults invalid values" do
    user = create_user!(email: "jp_per_page@example.com")
    sign_in_as(user)

    job_search = create_job_search!(user: user)
    company = create_company!
    3.times do |i|
      create_job_post!(company: company, job_search: job_search, website: "https://example.com/p#{i}", title: "T#{i}")
    end

    get job_posts_path, params: { per_page: 20 }
    expect(response).to have_http_status(:success)

    get job_posts_path, params: { per_page: 999 }
    expect(response).to have_http_status(:success)
  end
end
