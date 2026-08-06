# frozen_string_literal: true

class ResumeTextExtractionJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    return unless FeatureFlags.resume_recommendations_enabled?

    resume = Resume.find_by(id: resume_id)
    return unless resume

    Resumes::ExtractText.call(resume)
  end
end
