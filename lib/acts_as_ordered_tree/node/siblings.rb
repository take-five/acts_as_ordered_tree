# coding: utf-8

module ActsAsOrderedTree
  class Node
    module Siblings
      # Returns collection of all children of the parent, including self
      #
      # @return [ActiveRecord::Relation]
      def self_and_siblings
        scope.where( tree.columns.parent => parent_id ).preorder
      end

      # Returns collection of all children of the parent, except self
      #
      # @return [ActiveRecord::Relation]
      def siblings
        self_and_siblings.where( table[tree.columns.id].not_eq(id) )
      end

      # Returns siblings lying to the left of (upper than) current node.
      #
      # @return [ActiveRecord::Relation]
      def left_siblings
        siblings.where( table[tree.columns.position].lt(position) )
      end
      alias :higher_items :left_siblings

      # Returns a left (upper) sibling of node.
      #
      # @return [ActiveRecord::Base, nil]
      def left_sibling
        higher_items.last
      end
      alias :higher_item :left_sibling

      # Returns siblings lying to the right of (lower than) current node.
      #
      # @return [ActiveRecord::Relation]
      def right_siblings
        siblings.where( table[tree.columns.position].gt(position) )
      end
      alias :lower_items :right_siblings

      # Returns a right (lower) sibling of the node
      #
      # @return [ActiveRecord::Base, nil]
      def right_sibling
        right_siblings.first
      end
      alias :lower_item :right_sibling
    end
  end
end