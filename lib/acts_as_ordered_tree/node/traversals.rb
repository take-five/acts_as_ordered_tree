# coding: utf-8

require 'acts_as_ordered_tree/relation/arrangeable'
require 'acts_as_ordered_tree/relation/iterable'

module ActsAsOrderedTree
  class Node
    module Traversals
      # Returns relation that contains all node's parents, starting from root.
      #
      # @return [ActiveRecord::Relation]
      def ancestors
        iterable tree.adapter.ancestors(record)
      end

      # Returns relation that containt all node's parents
      # and node itself, starting from root.
      #
      # @return [ActiveRecord::Relation]
      def self_and_ancestors
        iterable tree.adapter.self_and_ancestors(record)
      end

      # Returns collection of all node's children including their nested children.
      #
      # @return [ActiveRecord::Relation]
      def descendants
        iterable tree.adapter.descendants(record)
      end

      # Returns collection of all node's children including their
      # nested children, and node itself.
      #
      # @return [ActiveRecord::Relation]
      def self_and_descendants
        iterable tree.adapter.self_and_descendants(record)
      end

      # Returns very first ancestor of current node. If current node is root,
      # then method returns node itself.
      #
      # @return [ActiveRecord::Base]
      def root
        root? ? record : ancestors.first
      end

      private
      def iterable(scope)
        scope.extending(Relation::Arrangeable, Relation::Iterable)
      end
    end # module Traversals
  end # module Node
end # module ActsAsOrderedTree