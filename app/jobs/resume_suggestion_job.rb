# frozen_string_literal: true

class ResumeSuggestionJob < ApplicationJob
  queue_as :default

  # Short, bounded retries so the UI does not stay pending forever.
  retry_on Llm::Client::RateLimitError, wait: 15.seconds, attempts: 3 do |job, error|
    job.mark_rate_limit_failed(error)
  end

  def perform(resume_suggestion_id)
    return unless FeatureFlags.resume_recommendations_enabled?

    suggestion = ResumeSuggestion.find_by(id: resume_suggestion_id)
    return unless suggestion

    Rails.logger.info("ResumeSuggestionJob starting id=#{resume_suggestion_id}")
    Resumes::GenerateSuggestions.call(suggestion: suggestion)
    Rails.logger.info("ResumeSuggestionJob finished id=#{resume_suggestion_id} status=#{suggestion.reload.status}")
  end

  def mark_rate_limit_failed(error)
    suggestion = ResumeSuggestion.find_by(id: arguments.first)
    suggestion&.update!(
      status: :failed,
      error_message: error.message.presence || "OpenAI rate limit reached. Wait a minute and try again."
    )
  end
end
