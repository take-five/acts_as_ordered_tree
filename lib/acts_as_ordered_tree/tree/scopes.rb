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
        if ordered_tree.columns.counter_cache?
          leaves_with_counter_cache
        else
          leaves_without_counter_cache
        end
      end

      private
      def leaves_without_counter_cache
        aliaz = Arel::Nodes::TableAlias.new(arel_table, 't')

        subquery = unscoped.select('1').
            from(aliaz).
            where(aliaz[ordered_tree.columns.parent].eq(arel_table[primary_key])).
            limit(1).
            reorder(nil)

        where "NOT EXISTS (#{subquery.to_sql})"
      end

      def leaves_with_counter_cache
        where arel_table[ordered_tree.columns.counter_cache].eq 0
      end
    end # module Scopes
  end # class Tree
end # module ActsAsOrderedTree