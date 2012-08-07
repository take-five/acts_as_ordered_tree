test_dir = File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"

require "rspec"
require "rspec-expectations"

require "simplecov"
SimpleCov.start

require "active_model"
require "active_record"
require "action_controller"
require "factory_girl"

require "acts_as_ordered_tree"
require "logger"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.logger = Logger.new(ENV['DEBUG'] ? $stderr : '/dev/null')
ActiveRecord::Migration.verbose = false
load(File.join(test_dir, "db", "schema.rb"))

require "rspec/rails"
require "shoulda-matchers"
require "support/models"
require "support/factories"
require "support/matchers"

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.use_transactional_fixtures = true

  config.around :each do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end
end