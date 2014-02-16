# coding: utf-8

require 'active_support/concern'

module ActsAsOrderedTree
  class Tree
    module Scopes
      extend ActiveSupport::Concern

      included do
        scope :preorder, -> { order(arel_table[ordered_tree.columns.position].asc) }
        scope :roots, -> { where(arel_table[ordered_tree.columns.parent].eq(nil)).preorder }

        # add +leaves+ scope only if counter_cache column present
        scope :leaves, -> { where(arel_table[ordered_tree.columns.counter_cache].eq(0)) } if
            ordered_tree.columns.counter_cache?

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