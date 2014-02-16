# coding: utf-8

require 'acts_as_ordered_tree/adapters/abstract'

module ActsAsOrderedTree
  module Adapters
    # Recursive adapter implements tree traversal in pure Ruby.
    class Recursive < Abstract
      def self_and_ancestors(node)
        preloaded(ancestors(node) + [node])
      end

      def ancestors(node)
        if node && node.parent
          preloaded(ancestors(node.parent) + [node.parent])
        else
          none
        end
      end

      def descendants(node)
        return none unless node.persisted?

        preloaded(node.children.map { |n| [n] + n.descendants }.reduce([], :+))
      end

      def self_and_descendants(node)
        return none unless node.persisted?

        preloaded([node] + descendants(node))
      end
    end
  end
end