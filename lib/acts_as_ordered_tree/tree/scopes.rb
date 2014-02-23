# coding: utf-8

module ActsAsOrderedTree
  class Tree
    module Scopes
      # Returns nodes ordered by their position.
      #
      # @return [ActiveRecord::Relation]
      def preorder
        order arel_table[ordered_tree.columns.position].asc
      end

      # Returns all nodes that don't have parent.
      #
      # @return [ActiveRecord::Relation]
      def roots
        preorder.where arel_table[ordered_tree.columns.parent].eq nil
      end

      # Returns all nodes that do not have any children. May be quite inefficient.
      #
      # @return [ActiveRecord::Relation]
      def root
        roots.first
      end

      # Returns all nodes that do not have any children. May be quite inefficient.
      #
      # @return [ActiveRecord::Relation]
      def leaves
        unless ordered_tree.columns.counter_cache?
          raise NotImplementedError, '.leaves scope requires counter_cache column, '\
                                       'at least in acts_as_ordered_tree 2.0'
        end

        where(arel_table[ordered_tree.columns.counter_cache].eq(0))
      end
    end # module Scopes
  end # class Tree
end # module ActsAsOrderedTree