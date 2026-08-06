# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resumes", type: :request, resume_recommendations: true do
  it "lists resumes for the signed-in user" do
    user = create_user!(email: "resumes_index@example.com")
    sign_in_as(user)
    create_resume!(user: user, name: "Backend Resume", extracted_text: "Ruby", extraction_status: :completed)

    get resumes_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Backend Resume")
  end

  it "shows an inline pdf preview on the resume page" do
    user = create_user!(email: "resumes_show_pdf@example.com")
    sign_in_as(user)
    resume = user.resumes.create!(
      name: "PDF Resume",
      extracted_text: "Ruby developer",
      extraction_status: :completed
    )
    resume.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "resume.pdf",
      content_type: "application/pdf"
    )

    get resume_path(resume)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("resumes-show__pdf")
    expect(response.body).to include("Extracted text used for suggestions")
  end

  it "uploads a resume and enqueues text extraction" do
    user = create_user!(email: "resumes_create@example.com")
    sign_in_as(user)

    file = Tempfile.new([ "resume", ".txt" ])
    file.write("Ruby developer")
    file.rewind
    uploaded = Rack::Test::UploadedFile.new(file.path, "text/plain")

    expect {
      post resumes_path, params: {
        resume: {
          name: "Main Resume",
          file: uploaded,
          is_default: "1"
        }
      }
    }.to have_enqueued_job(ResumeTextExtractionJob)

    resume = Resume.order(created_at: :desc).first
    expect(response).to redirect_to(resumes_path)
    expect(resume.name).to eq("Main Resume")
    expect(resume.is_default?).to be(true)
  ensure
    file&.close
    file&.unlink
  end

  it "requires login" do
    get resumes_path
    expect(response).to redirect_to(login_path)
  end
end
