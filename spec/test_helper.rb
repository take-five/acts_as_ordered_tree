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

  before_reorder :on_before_reorder
  after_reorder  :on_after_reorder
  around_reorder :on_around_reorder
  before_move    :on_before_move
  after_move     :on_after_move
  around_move    :on_around_move

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

  # stub
  def on_before_reorder;end
  def on_after_reorder;end
  def on_around_reorder;yield end
  def on_before_move; end
  def on_after_move; end
  def on_around_move; yield end
end