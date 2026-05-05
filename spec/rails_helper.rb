require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "active_job/test_helper"
require "active_support/testing/time_helpers"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include AuthHelpers, type: :request
  config.include ModelHelpers
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:suite) do
    ActiveJob::Base.queue_adapter = :test
  end

  config.before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

