# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'acts_as_ordered_tree/version'

Gem::Specification.new do |s|
  s.name        = 'acts_as_ordered_tree'
  s.version     = ActsAsOrderedTree::VERSION
  s.authors     = ['Alexei Mikhailov', 'Vladimir Kuznetsov']
  s.email       = %w(amikhailov83@gmail.com kv86@mail.ru)
  s.homepage    = 'https://github.com/take-five/acts_as_ordered_tree'
  s.summary     = %q{ActiveRecord extension for sorted adjacency lists support}

  s.rubyforge_project = 'acts_as_ordered_tree'

  s.files         = `git ls-files -- lib/*`.split("\n")
  s.test_files    = `git ls-files -- spec/* features/*`.split("\n")
  s.require_paths = %w(lib)

  s.add_dependency 'activerecord', '>= 3.1.0'
  s.add_dependency 'activerecord-hierarchical_query', '~> 0.0.7'

  s.add_development_dependency 'rake', '~> 10.3.2'
  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rspec', '~> 2.99.0'
  s.add_development_dependency 'database_cleaner', '~> 1.3.0'
  s.add_development_dependency 'factory_girl', '~> 4.4.0'
  s.add_development_dependency 'appraisal', '>= 1.0.2'
end