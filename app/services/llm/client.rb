# frozen_string_literal: true

module Llm
  class Client
    class Error < StandardError; end
    class RateLimitError < Error; end

    # Keep in-process retries short; ActiveJob handles longer backoff.
    MAX_RETRIES = 2
    BASE_DELAY_SECONDS = 1
    MAX_DELAY_SECONDS = 5

    def chat(system:, user:)
      if api_key.blank?
        raise Error, "OpenAI API key is not configured. Set OPENAI_API_KEY in your environment."
      end

      with_retries do
        response = client.chat(
          parameters: {
            model: model,
            messages: [
              { role: "system", content: system },
              { role: "user", content: user }
            ],
            response_format: { type: "json_object" },
            max_tokens: max_tokens
          }
        )

        content = response.dig("choices", 0, "message", "content")
        raise Error, "Empty response from LLM" if content.blank?

        content
      end
    end

    private

    def with_retries
      attempts = 0

      begin
        attempts += 1
        yield
      rescue Faraday::TooManyRequestsError => e
        raise RateLimitError, rate_limit_message(e) if attempts > MAX_RETRIES

        delay = retry_delay(e, attempts)
        Rails.logger.warn("OpenAI rate limited (attempt #{attempts}/#{MAX_RETRIES}); retrying in #{delay}s")
        sleep(delay)
        retry
      rescue Faraday::Error => e
        raise Error, "OpenAI request failed: #{e.message}"
      end
    end

    def retry_delay(error, attempts)
      header_delay = retry_after_seconds(error)
      delay = header_delay || (BASE_DELAY_SECONDS * (2**(attempts - 1)))
      [ delay, MAX_DELAY_SECONDS ].min
    end

    def retry_after_seconds(error)
      headers = error.response&.dig(:headers)
      return unless headers

      value = headers["retry-after"] || headers["Retry-After"]
      return if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def rate_limit_message(error)
      body = error.response&.dig(:body)
      detail = body.is_a?(Hash) ? body.dig("error", "message") : body.to_s
      detail = detail.to_s.truncate(200).presence

      [
        "OpenAI rate limit reached. Wait a minute and try again.",
        detail
      ].compact.join(" ")
    end

    def client
      @client ||= OpenAI::Client.new(access_token: api_key, request_timeout: 120)
    end

    def api_key
      ENV["OPENAI_API_KEY"]
    end

    def model
      ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
    end

    def max_tokens
      ENV.fetch("OPENAI_MAX_TOKENS", "1200").to_i
    end
  end
end
