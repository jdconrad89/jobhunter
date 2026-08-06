# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::ExtractText do
  it "extracts plain text from an attached resume file" do
    user = create_user!
    resume = user.resumes.create!(name: "Resume", extraction_status: :pending)
    attach_text_resume!(resume, content: "Built APIs with Ruby on Rails")

    described_class.call(resume)

    resume.reload
    expect(resume.extraction_status).to eq("completed")
    expect(resume.extracted_text).to include("Built APIs with Ruby on Rails")
  end

  it "marks extraction as failed when the file type is unsupported" do
    user = create_user!
    resume = user.resumes.create!(name: "Resume", extraction_status: :pending)
    resume.file.attach(
      io: StringIO.new("data"),
      filename: "resume.exe",
      content_type: "application/octet-stream"
    )

    expect { described_class.call(resume) }.to raise_error("Unsupported file type")

    resume.reload
    expect(resume.extraction_status).to eq("failed")
    expect(resume.extraction_error).to eq("Unsupported file type")
  end

  it "applies light normalization to extracted pdf text" do
    user = create_user!
    resume = user.resumes.create!(name: "Resume", extraction_status: :pending)
    resume.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "resume.pdf",
      content_type: "application/pdf"
    )

    allow(Resumes::PdfTextExtractor).to receive(:call).and_return("J A S O N\nSeniorSoftware Engineer")
    allow_any_instance_of(described_class).to receive(:pdftotext_available?).and_return(false)

    described_class.call(resume)

    resume.reload
    expect(resume.extracted_text).to include("JASON")
    expect(resume.extracted_text).to include("Senior Software Engineer")
  end
end
