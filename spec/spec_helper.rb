ENV['DB'] ||= 'pg'
test_dir = File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"

require "rspec"
require "rspec-expectations"

begin
  require "simplecov"
  SimpleCov.start
rescue LoadError
  #ignore
end

require "active_record"
require "factory_girl"

require "acts_as_ordered_tree"
require "logger"
require "yaml"
require "erb"

config_file = ENV['DBCONF'] || 'config.yml'

ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(File.join(test_dir, 'db', config_file))).result)
ActiveRecord::Base.establish_connection(ENV['DB'])
ActiveRecord::Base.logger = Logger.new(ENV['DEBUG'] ? $stderr : '/dev/null')
ActiveRecord::Migration.verbose = false
load(File.join(test_dir, "db", "schema.rb"))

require "shoulda-matchers"
require "support/models"
require "support/factories"
require "support/matchers"

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