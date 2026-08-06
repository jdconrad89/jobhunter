# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeatureFlags do
  after { ENV.delete("RESUME_RECOMMENDATIONS_ENABLED") }

  it "is disabled by default" do
    ENV.delete("RESUME_RECOMMENDATIONS_ENABLED")
    expect(described_class.resume_recommendations_enabled?).to be(false)
  end

  it "is enabled when RESUME_RECOMMENDATIONS_ENABLED is true" do
    ENV["RESUME_RECOMMENDATIONS_ENABLED"] = "true"
    expect(described_class.resume_recommendations_enabled?).to be(true)
  end

  it "is disabled when RESUME_RECOMMENDATIONS_ENABLED is false" do
    ENV["RESUME_RECOMMENDATIONS_ENABLED"] = "false"
    expect(described_class.resume_recommendations_enabled?).to be(false)
  end
end
