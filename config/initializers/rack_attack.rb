# frozen_string_literal: true

# Rate limiting for auth and API endpoints.
# Disabled in test by default to avoid flaky specs.
Rack::Attack.enabled = false if Rails.env.test?

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

Rack::Attack.safelist("allow health check") do |req|
  req.path == "/up"
end

Rack::Attack.throttle("logins/ip", limit: 10, period: 3.minutes) do |req|
  req.ip if req.post? && req.path == "/login"
end

Rack::Attack.throttle("signups/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.post? && req.path == "/signup"
end

Rack::Attack.throttle("api/ip", limit: 120, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/")
end

Rack::Attack.throttle("api/token", limit: 30, period: 1.minute) do |req|
  req.env["HTTP_AUTHORIZATION"] if req.path.start_with?("/api/")
end

Rack::Attack.throttled_responder = lambda do |request|
  if request.path.start_with?("/api/")
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  else
    [ 429, { "Content-Type" => "text/plain" }, [ "Too many requests. Please try again later." ] ]
  end
end
