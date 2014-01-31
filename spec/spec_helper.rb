ENV['DB'] ||= 'pg'

require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'rspec-expectations'

begin
  require 'simplecov'
  SimpleCov.command_name "rspec/#{File.basename(ENV['BUNDLE_GEMFILE'])}/#{ENV['DB']}"
  SimpleCov.start 'test_frameworks'
rescue LoadError
  #ignore
end

require 'db/boot'

require 'factory_girl'

require 'shoulda-matchers'
require 'support/factories'
require 'support/matchers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around :each, :transactional do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  config.around :each, :non_transactional do |example|
    begin
      example.run
    ensure
      Default.delete_all
      DefaultWithCounterCache.delete_all
      DefaultWithCallbacks.delete_all
      Scoped.delete_all
    end
  end
end