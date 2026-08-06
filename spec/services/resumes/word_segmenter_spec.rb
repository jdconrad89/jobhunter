# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resumes::WordSegmenter do
  it "splits glued resume phrasing into words" do
    expect(described_class.call("withnearly")).to eq("with nearly")
    expect(described_class.call("specializingin")).to eq("specializing in")
    expect(described_class.call("softwarearchitecture")).to eq("software architecture")
    expect(described_class.call("RubyonRails")).to eq("Ruby on Rails")
  end

  it "does not break normal spaced text" do
    input = "Experienced Senior Software Engineer specializing in Ruby on Rails"

    expect(described_class.call(input)).to eq(input)
  end

  it "leaves unknown long tokens alone when they cannot be segmented cleanly" do
    expect(described_class.call("xyzqwertylmnop")).to eq("xyzqwertylmnop")
  end
end
