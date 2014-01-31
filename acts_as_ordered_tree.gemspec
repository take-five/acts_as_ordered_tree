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
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = %w(lib)

  s.add_dependency 'activerecord', '>= 3.0.0'

  s.add_development_dependency 'rake', '>= 0.9.2'
  s.add_development_dependency 'bundler', '>= 1.0'
  s.add_development_dependency 'rspec', '>= 2.11'
  s.add_development_dependency 'shoulda-matchers', '>= 1.2.0'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'factory_girl', '< 3'
  s.add_development_dependency 'appraisal', '>= 0.4.0'
end