# frozen_string_literal: true

module FeatureFlagHelpers
  def enable_resume_recommendations!
    allow(FeatureFlags).to receive(:resume_recommendations_enabled?).and_return(true)
  end

  def disable_resume_recommendations!
    allow(FeatureFlags).to receive(:resume_recommendations_enabled?).and_return(false)
  end
end

RSpec.configure do |config|
  config.include FeatureFlagHelpers

  config.before(:each, :resume_recommendations) do
    enable_resume_recommendations!
  end
end
