# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/adapters/recursive'
require 'adapters/shared'

describe ActsAsOrderedTree::Adapters::Recursive, :transactional do
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::Recursive, :default
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::Recursive, :default_with_counter_cache
  it_behaves_like 'ActsAsOrderedTree adapter', ActsAsOrderedTree::Adapters::Recursive, :scoped
end