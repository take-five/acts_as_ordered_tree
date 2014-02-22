# coding: utf-8

require 'active_support/concern'

module ActsAsOrderedTree
  class Tree
    module Scopes
      extend ActiveSupport::Concern

      included do
        scope :preorder, -> { order(arel_table[ordered_tree.columns.position].asc) }
        scope :roots, -> { where(arel_table[ordered_tree.columns.parent].eq(nil)).preorder }

        # Returns all nodes that do not have any children. May be quite inefficient.
        #
        # @return [ActiveRecord::Relation]
        scope :leaves, -> {
          unless ordered_tree.columns.counter_cache?
            raise NotImplementedError, '.leaves scope requires counter_cache column, '\
                                       'at least in acts_as_ordered_tree 2.0'
          end

          where(arel_table[ordered_tree.columns.counter_cache].eq(0))
        }

        # Returns the first root
        #
        # @return [ActiveRecord::Base, nil]
        def self.root
          roots.first
        end
      end
    end
  end
end