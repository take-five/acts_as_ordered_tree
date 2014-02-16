# coding: utf-8

require 'active_support/hash_with_indifferent_access'
require 'acts_as_ordered_tree/adapters/recursive'
require 'acts_as_ordered_tree/adapters/postgresql'

module ActsAsOrderedTree
  module Adapters
    # adapters map
    ADAPTERS = HashWithIndifferentAccess[:PostgreSQL => PostgreSQL]
    ADAPTERS.default = Recursive

    def self.lookup(name)
      ADAPTERS[name]
    end
  end
end