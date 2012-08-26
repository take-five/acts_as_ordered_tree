require "acts_as_ordered_tree/relation/base"

module ActsAsOrderedTree
  module Relation
    # Recursive relation fixes Rails3.0 issue https://github.com/rails/rails/issues/522 for
    # relations with joins to subqueries
    class Recursive < Base
      attr_accessor :recursive_table_value, :recursive_query_value

      # relation.with_recursive("table_name", "SELECT * FROM table_name")
      def with_recursive(recursive_table_name, query)
        relation = clone
        relation.recursive_table_value = recursive_table_name
        relation.recursive_query_value = query
        relation
      end

      def build_arel
        if recursive_table_value && recursive_query_value
          join_sql = "INNER JOIN (" +
                       recursive_query_sql +
                     ") AS #{recursive_table_value} ON #{recursive_table_value}.id = #{table.name}.id"

          except(:recursive_table, :recursive_query).joins(join_sql).build_arel
        else
          super
        end
      end

      def update_all(updates, conditions = nil, options = {})
        if recursive_table_value && recursive_query_value
          scope = where("id IN (SELECT id FROM (#{recursive_query_sql}) AS #{recursive_table_value})").
              except(:recursive_table, :recursive_query, :limit, :order)

          scope.update_all(updates, conditions, options)
        else
          super
        end
      end

      def except(*skips)
        result = super
        ([:recursive_table, :recursive_query] - skips).each do |method|
          result.send("#{method}_value=", send(:"#{method}_value"))
        end

        result
      end

      private
      def recursive_query_sql
        "WITH RECURSIVE #{recursive_table_value} AS (#{recursive_query_value}) " +
        "SELECT * FROM #{recursive_table_value}"
      end
    end
  end
end