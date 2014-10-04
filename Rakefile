require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yaml'
require 'erb'

namespace :db do
  config_name = ENV['DBCONF'] || 'config.yml'

  databases = YAML.load(ERB.new(IO.read(File.join(File.dirname(__FILE__), 'spec', 'support', 'db', config_name))).result)

  databases.each do |name, spec|
    desc "Run given task for #{spec['adapter']} database"
    task name do
      with_database(name) do
        announce
        exec
      end
    end
  end

  task :all do
    require 'benchmark'

    time = Benchmark.realtime do
      databases.keys.each do |name|
        with_database(name) do
          announce
          run
        end
      end
    end

    puts
    puts 'Time taken: %.2f sec' % time

    exit
  end

  private
  def exec
    Kernel.exec(ENV, *command)
  end

  def run
    unless Kernel.system(ENV, *command)
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
    ['bundle', 'exec', 'rake', *ARGV.slice(1, ARGV.size)]
  end

  def announce
    puts ">> DB=#{ENV['DB']} #{command.join(' ')}"
  end
end

desc 'Run given task for all databases'
task :db => 'db:all'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--color --format progress'
end


begin
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new
rescue LoadError, NameError
  task 'coveralls:push'
end

namespace :coverage do
  desc 'Turn on code coverage'
  task :enable do
    ENV['COVERAGE'] = '1' unless ENV.key?('COVERAGE')
  end

  desc 'Turn off code coverage'
  task :disable do
    ENV['COVERAGE'] = ''
  end

  desc 'Push code coverage to coveralls'
  task :push => 'coveralls:push'
end

task :spec => 'coverage:enable'