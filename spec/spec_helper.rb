ENV['RAILS_ENV'] = 'test'

require 'bundler/setup'
require 'pry'
require 'database_cleaner'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec/'
  add_filter 'vendor/'
end

require_relative 'dummy/config/environment'
require_relative 'dummy/db/schema'

require 'onsi'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
