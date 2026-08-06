# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::NormalizeExtractedText do
  it "collapses letter-spaced all-caps headers" do
    output = described_class.call("J A S O N   C O N R A D\nEMPLOYMENT HISTORY")

    expect(output).to include("JASON CONRAD")
    expect(output).to include("EMPLOYMENT HISTORY")
  end

  it "splits clear camelCase joins and glued words without breaking normal prose" do
    input = "SeniorSoftware Engineer withnearly8years specializinginRubyonRails,softwarearchitecture"

    output = described_class.call(input)

    expect(output).to include("Senior Software Engineer")
    expect(output).to include("with nearly")
    expect(output).to include("specializing in")
    expect(output).to include("software architecture")
  end

  it "strips excessive indentation while preserving line breaks" do
    input = "                                    JASON CONRAD\n\nExperienced engineer"

    output = described_class.call(input)

    expect(output).to include("JASON CONRAD")
    expect(output).to include("Experienced engineer")
    expect(output).not_to match(/^\s{10,}/)
  end

  it "does not insert spaces into normal words" do
    input = "Experienced Senior Software Engineer specializing in Ruby on Rails"

    expect(described_class.call(input)).to eq(input)
  end
end
