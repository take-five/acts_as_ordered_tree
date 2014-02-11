require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'appraisal'
require 'cucumber'
require 'cucumber/rake/task'
require 'yaml'
require 'erb'

namespace :db do
  config_name = ENV['DBCONF'] || 'config.yml'

  databases = YAML.load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'spec', 'db', config_name))).result)

  databases.each do |name, spec|
    desc "Run given task for #{spec['adapter']} database"
    task name do
      with_database(name) do
        announce
        exec
      end
    end
  end

  desc 'Run given task for all databases'
  task :all do
    require 'benchmark'

    time = Benchmark.realtime do
      databases.keys.each do |name|
        with_database(name) do
          announce
          #run
        end
      end
    end

    puts
    puts 'Time taken: %.2f sec' % (time * 1000)

    exit
  end

  private
  def exec
    Kernel.exec(command)
  end

  def run
    unless Kernel.system(command)
      exit(1)
    end
  end

  def with_database(name)
    ENV['DB'] = name

    yield
  ensure
    ENV['DB'] = nil
  end

  def command
    "DB=#{ENV['DB']} bundle exec rake " + ARGV.slice(1, ARGV.size).join(' ')
  end

  def announce
    puts ">> #{command}"
  end
end

desc 'Run given task for all databases'
task :db => 'db:all'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = 'features --format progress --tags ~@wip'
end

desc 'Run all test suits'
task :test => [:spec, :features]