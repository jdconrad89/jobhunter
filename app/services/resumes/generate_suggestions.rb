# frozen_string_literal: true

module Resumes
  class GenerateSuggestions
    Result = Data.define(:success?, :suggestion, :errors)

    def self.call(suggestion:)
      new(suggestion: suggestion).call
    end

    def initialize(suggestion:)
      @suggestion = suggestion
    end

    def call
      resume = suggestion.resume
      job_post = suggestion.job_post

      unless resume.text_ready?
        return fail_with("Resume text is not ready yet. Wait for extraction to complete.")
      end

      prompt = BuildSuggestionPrompt.call(resume: resume, job_post: job_post)
      raw = Llm::Client.new.chat(system: prompt[:system], user: prompt[:user])
      parsed = JSON.parse(raw)

      suggestion.update!(status: :completed, suggestions: parsed, error_message: nil)
      Result.new(success?: true, suggestion: suggestion, errors: nil)
    rescue Llm::Client::RateLimitError => e
      # Keep pending so the job can retry; surface the reason to the polling UI.
      suggestion.update!(
        status: :pending,
        error_message: e.message.presence || "OpenAI rate limit reached. Retrying…"
      )
      raise
    rescue JSON::ParserError => e
      fail_with("Failed to parse LLM response: #{e.message}")
    rescue Llm::Client::Error => e
      fail_with(e.message)
    rescue StandardError => e
      fail_with(e.message)
    end

    private

    attr_reader :suggestion

    def fail_with(message)
      suggestion.update!(status: :failed, error_message: message)
      Result.new(success?: false, suggestion: suggestion, errors: [ message ])
    end
  end
end
