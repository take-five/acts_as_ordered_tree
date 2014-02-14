ENV['DB'] ||= 'pg'

require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'rspec-expectations'

unless ENV['NOCOV']
  begin
    require 'simplecov'
    SimpleCov.command_name "rspec/#{File.basename(ENV['BUNDLE_GEMFILE'])}/#{ENV['DB']}"
    SimpleCov.start 'test_frameworks'
  rescue LoadError
    #ignore
  end
end

require 'support/db/boot'

require 'factory_girl'
silence_warnings { require 'shoulda-matchers' }
require 'support/factories'
require 'support/matchers'
require 'database_cleaner'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around :each, :transactional do |example|
    DatabaseCleaner.strategy = :transaction

    DatabaseCleaner.start

    example.run

    DatabaseCleaner.clean
  end

  config.around :each, :non_transactional do |example|
    DatabaseCleaner.strategy = :truncation

    DatabaseCleaner.start

    example.run

    DatabaseCleaner.clean
  end
end