# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/adapters/postgresql'
require 'adapters/shared'

describe ActsAsOrderedTree::Adapters::PostgreSQL, :transactional, :pg do
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::PostgreSQL, :default
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::PostgreSQL, :default_with_counter_cache
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::PostgreSQL, :scoped
end