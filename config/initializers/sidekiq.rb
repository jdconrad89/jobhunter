# Sidekiq is optional in development (see JOB_QUEUE_ADAPTER). Production uses Solid Queue.
return unless Rails.application.config.active_job.queue_adapter == :sidekiq

require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
