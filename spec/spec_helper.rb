require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/spec/"
end

SimpleCov.minimum_coverage line: 90, branch: 70

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
