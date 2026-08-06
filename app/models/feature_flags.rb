# frozen_string_literal: true

module FeatureFlags
  module_function

  # Resume upload + job-post suggestion recommendations.
  # Disabled by default. Enable with RESUME_RECOMMENDATIONS_ENABLED=true
  def resume_recommendations_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("RESUME_RECOMMENDATIONS_ENABLED", "false"))
  end
end
