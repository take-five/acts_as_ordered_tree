require "acts_as_ordered_tree/relation/recursive"

module ActsAsOrderedTree
  module Adapters
    module PostgreSQLAdapter
      # Recursive ancestors fetcher
      def self_and_ancestors
        if persisted? && !send("#{parent_column}_changed?")
          query = <<-QUERY
            SELECT id, #{parent_column}, 1 AS _depth
            FROM #{self.class.quoted_table_name}
            WHERE #{arel[:id].eq(id).to_sql}
            UNION ALL
            SELECT alias1.id, alias1.#{parent_column}, _depth + 1
            FROM #{self.class.quoted_table_name} alias1
              INNER JOIN self_and_ancestors ON alias1.id = self_and_ancestors.#{parent_column}
          QUERY

          recursive_scope.with_recursive("self_and_ancestors", query).
                          order("self_and_ancestors._depth DESC")
        else
          ancestors + [self]
        end
      end

      # Recursive ancestors fetcher
      def ancestors
        query = <<-QUERY
          SELECT id, #{parent_column}, 1 AS _depth
          FROM #{self.class.quoted_table_name}
          WHERE #{arel[:id].eq(parent.try(:id)).to_sql}
          UNION ALL
          SELECT alias1.id, alias1.#{parent_column}, _depth + 1
          FROM #{self.class.quoted_table_name} alias1
            INNER JOIN ancestors ON alias1.id = ancestors.#{parent_column}
        QUERY

        recursive_scope.with_recursive("ancestors", query).
                        order("ancestors._depth DESC")
      end

      def root
        root? ? self : ancestors.first
      end

      def self_and_descendants
        query = <<-QUERY
          SELECT id, #{parent_column}, ARRAY[#{position_column}] AS _positions
          FROM #{self.class.quoted_table_name}
          WHERE #{arel[:id].eq(id).to_sql}
          UNION ALL
          SELECT alias1.id, alias1.#{parent_column}, _positions || alias1.#{position_column}
          FROM descendants INNER JOIN
            #{self.class.quoted_table_name} alias1 ON alias1.parent_id = descendants.id
        QUERY

        recursive_scope.with_recursive("descendants", query).
                        order("descendants._positions ASC")
      end

      def descendants
        self_and_descendants.where(arel[:id].not_eq(id))
      end

      private
      def recursive_scope
        ActsAsOrderedTree::Relation::Recursive.new(ordered_tree_scope)
      end
    end
  end
end