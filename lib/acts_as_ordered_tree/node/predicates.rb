# coding: utf-8

module ActsAsOrderedTree
  class Node
    module Predicates
      # Returns true if this is a root node.
      def root?
        !parent_id?
      end

      # Returns true if this is the end of a branch.
      def leaf?
        record.persisted? && if children.loaded? || tree.columns.counter_cache?
                               # no SQL-queries here
                               children.empty?
                             else
                               !children.exists?
                             end
      end

      # Returns true if node contains any children.
      def branch?
        !leaf?
      end

      # Returns true is node is not a root node.
      def child?
        !root?
      end

      # Returns true if current node is descendant of +other+ node.
      #
      # @param [ActiveRecord::Base] other
      def is_descendant_of?(other)
        same_scope?(other) &&
            ancestors.include?(other) &&
            ancestors.all? { |x| x.ordered_tree_node.same_scope?(record) }
      end

      # Returns true if current node is equal to +other+ node or is descendant of +other+ node.
      #
      # @param [ActiveRecord::Base] other
      def is_or_is_descendant_of?(other)
        record == other || is_descendant_of?(other)
      end

      # Returns true if current node is ancestor of +other+ node.
      #
      # @param [ActiveRecord::Base] other
      def is_ancestor_of?(other)
        same_scope?(other) && other.is_descendant_of?(record)
      end

      # Returns true if current node is equal to +other+ node or is ancestor of +other+ node.
      #
      # @param [ActiveRecord::Base] other
      def is_or_is_ancestor_of?(other)
        same_scope?(other) && other.is_or_is_descendant_of?(record)
      end

      # Return +true+ if this object is the first in the list.
      def first?
        position <= 1
      end

      # Return +true+ if this object is the last in the list.
      def last?
        if tree.columns.counter_cache? && parent
          parent.children.size == position
        else
          !right_sibling
        end
      end

      # Check if other node is in the same scope.
      #
      # @api private
      def same_scope?(other)
        same_kind?(other) && tree.columns.scope.all? do |attr|
          record[attr] == other[attr]
        end
      end

      # Check if other node has the same parent
      #
      # @api private
      def same_parent?(other)
        same_scope?(other) && parent_id == other.ordered_tree_node.parent_id
      end

      private
      # Check if other node belongs to same class hierarchy.
      def same_kind?(other)
        other.ordered_tree && other.ordered_tree.base_class == tree.base_class
      end
    end # module Predicates
  end # class Node
end # module ActsAsOrderedTree