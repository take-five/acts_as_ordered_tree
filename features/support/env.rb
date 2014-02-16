# coding: utf-8

require 'bundler/setup'
require 'cucumber/rspec/doubles'
require 'database_cleaner'
require 'active_support/core_ext/object/blank'

ENV['DB'] ||= 'pg'

if ENV['COVERAGE'].present?
  begin
    require 'simplecov'
    SimpleCov.command_name "cucumber/#{File.basename(ENV['BUNDLE_GEMFILE'])}/#{ENV['DB']}"
    SimpleCov.start 'test_frameworks'
  rescue LoadError
    #ignore
  end
end

require File.expand_path('../../spec/support/db/boot', File.dirname(__FILE__))

DatabaseCleaner.strategy = :truncation

Around do |*, block|
  DatabaseCleaner.start

  block.call

  DatabaseCleaner.clean
end

# SQLite3 is not concurrent database really.
# It can cause really weird issues in concurrent environments.
#
#   SQLite3::BusyException: database is locked
#
# This exception occurs anywhere, in such random places I couldn't even think about.
# I give up, I can't fight with it anymore.
Around('@concurrent') do |*, block|
  block.call unless ENV['DB'] == 'sqlite3'
end