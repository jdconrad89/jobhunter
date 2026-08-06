# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::Create do
  it "returns errors when the resume is invalid" do
    user = create_user!(email: "resume_create_invalid@example.com")

    result = described_class.call(
      user: user,
      attributes: { name: "", file: nil }
    )

    expect(result.success?).to be(false)
    expect(result.errors).to include("Name can't be blank")
  end
end
