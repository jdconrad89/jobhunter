# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume, type: :model do
  it "requires a name" do
    user = create_user!
    resume = user.resumes.build(name: "")

    expect(resume).not_to be_valid
    expect(resume.errors[:name]).to include("can't be blank")
  end

  it "validates accepted file types" do
    user = create_user!
    resume = user.resumes.build(name: "Resume")
    resume.file.attach(
      io: StringIO.new("data"),
      filename: "resume.exe",
      content_type: "application/octet-stream"
    )

    expect(resume).not_to be_valid
    expect(resume.errors[:file]).to include("must be a PDF, DOCX, or plain text file")
  end

  it "reports when text is ready" do
    user = create_user!
    resume = create_resume!(
      user: user,
      extracted_text: "Ruby on Rails developer",
      extraction_status: :completed
    )

    expect(resume.text_ready?).to be(true)
  end

  it "detects pdf attachments" do
    user = create_user!
    resume = user.resumes.create!(name: "Resume", extraction_status: :pending)
    resume.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "resume.pdf",
      content_type: "application/pdf"
    )

    expect(resume.pdf?).to be(true)
    expect(resume.docx?).to be(false)
  end
end
