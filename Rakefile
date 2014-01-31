require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'appraisal'
require 'cucumber'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = 'features --format pretty --tags ~@wip'
end

desc 'Run all test suits'
task :test => [:spec, :features]