# frozen_string_literal: true

module JobPosts
  module SafeUrl
    module_function

    def http_url(raw)
      return if raw.blank?

      uri = URI.parse(raw.to_s.strip)
      return unless uri.is_a?(URI::HTTP)
      return unless %w[http https].include?(uri.scheme)
      return if uri.host.blank?

      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def http_url?(raw)
      http_url(raw).present?
    end
  end
end
