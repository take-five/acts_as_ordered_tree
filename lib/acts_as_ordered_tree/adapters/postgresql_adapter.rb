require 'acts_as_ordered_tree/arrangeable'
require 'acts_as_ordered_tree/relation/preloaded'

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

          with_recursive_join(query, 'self_and_ancestors').
              order('self_and_ancestors._depth DESC').
              extending(Arrangeable)
        else
          (ancestors + [self]).tap { |ary| ary.extend(Arrangeable) }
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

        with_recursive_join(query, 'ancestors').
            order('ancestors._depth DESC').
            extending(Arrangeable)
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

        with_recursive_join(query, 'descendants').
            order('descendants._positions ASC').
            extending(Arrangeable)
      end

      def descendants
        self_and_descendants.where(arel[:id].not_eq(id))
      end

      private
      def recursive_scope
        ActsAsOrderedTree::Relation::Recursive.new(ordered_tree_scope)
      end

      def with_recursive_join(recursive_query_sql, aliaz)
        join_sql = 'INNER JOIN (' +
            "WITH RECURSIVE #{aliaz} AS (" +
            recursive_query_sql +
            ") SELECT * FROM #{aliaz} " +
            ") #{aliaz} ON #{aliaz}.id = #{self.class.quoted_table_name}.id"

        ordered_tree_scope.joins(join_sql)
      end

      # Rails 3.0 does not support update_all with joins, so we patch it :(
      if ActiveRecord::VERSION::STRING <= '3.1.0'
        module Rails30UpdateAllPatch
          def update_all(updates, conditions = nil, options = {})
            relation = except(:joins, :where).
                where(:id => select(klass.arel_table[:id]).except(:order, :limit).arel)
            relation.update_all(updates, conditions, options)
          end
        end

        def with_recursive_join_30(recursive_query_sql, aliaz)
          relation = with_recursive_join_31(recursive_query_sql, aliaz)
          relation.extend(Rails30UpdateAllPatch)
          relation
        end
        alias_method :with_recursive_join_31, :with_recursive_join
        alias_method :with_recursive_join, :with_recursive_join_30
      end
    end
  end
end