require File.expand_path('../../init', __FILE__)

require "rspec"
require "rspec-expectations"

require "simplecov"
SimpleCov.start

require "acts_as_ordered_tree"
require "logger"

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(config['database'])
ActiveRecord::Base.logger = Logger.new(ENV['DEBUG'] ? $stderr : '/dev/null')

# Create schema
ActiveRecord::Base.connection.create_table :nodes do |t|
  t.integer :parent_id
  t.integer :position
  t.string  :name
end

class Node < ActiveRecord::Base
  acts_as_ordered_tree

  def self.debug
    buf = StringIO.new("", "w")

    roots.each do |n|
      buf.puts "! #{n.name}"
      n.descendants.each do |d|
        buf.puts "#{' ' * d.level * 2} (##{d.id}): #{d.name} @ #{d.position}"
      end
    end

    print buf.string
  end
end