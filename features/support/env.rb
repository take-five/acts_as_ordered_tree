# coding: utf-8

require 'bundler/setup'
require 'cucumber/rspec/doubles'
require 'database_cleaner'
#require 'database_cleaner/cucumber'

ENV['DB'] ||= 'pg'

begin
  require 'simplecov'
  SimpleCov.command_name "cucumber/#{File.basename(ENV['BUNDLE_GEMFILE'])}/#{ENV['DB']}"
  SimpleCov.start 'test_frameworks'
rescue LoadError
  #ignore
end

require File.expand_path('../../spec/db/boot', File.dirname(__FILE__))

DatabaseCleaner.strategy = :transaction

Around('~@concurrent') do |*, block|
  DatabaseCleaner.start

  block.call

  DatabaseCleaner.clean
end

Before('@concurrent') do
  connection = ActiveRecord::Base.connection

  connection.tables.each do |table|
    connection.execute "DELETE FROM #{connection.quote_table_name table}"
  end
end