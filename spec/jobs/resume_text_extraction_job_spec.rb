# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeTextExtractionJob, type: :job, resume_recommendations: true do
  it "extracts text from the resume" do
    user = create_user!
    resume = user.resumes.create!(name: "Resume", extraction_status: :pending)
    attach_text_resume!(resume, content: "Senior engineer")

    described_class.perform_now(resume.id)

    resume.reload
    expect(resume.extracted_text).to include("Senior engineer")
    expect(resume.extraction_status).to eq("completed")
  end
end
