# This script establishes connection, creates DB schema and loads models definitions.
# Used by both rspec and cucumber

require 'active_record'
require 'active_support/core_ext/module' # rails 3.0 workaround
require 'acts_as_ordered_tree'

require 'logger'
require 'yaml'
require 'erb'

base_dir = File.dirname(__FILE__)
config_file = File.join(base_dir, ENV['DBCONF'] || 'config.yml')

ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(config_file)).result)
ActiveRecord::Base.establish_connection(ENV['DB'])
ActiveRecord::Base.logger = Logger.new(ENV['DEBUG'] ? $stderr : '/dev/null')
ActiveRecord::Migration.verbose = false
I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales=)

load(File.join(base_dir, 'schema.rb'))

require File.join(base_dir, '..', 'support', 'models')