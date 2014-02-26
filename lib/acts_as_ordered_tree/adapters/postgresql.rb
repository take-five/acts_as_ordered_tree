# coding: utf-8

require 'acts_as_ordered_tree/adapters/abstract'
require 'acts_as_ordered_tree/relation/preloaded'
require 'acts_as_ordered_tree/relation/recursive'

module ActsAsOrderedTree
  module Adapters
    # PostgreSQL adapter implements traverse operations with CTEs
    class PostgreSQL < Abstract
      attr_reader :tree

      delegate :columns, :to => :tree
      delegate :quote_column_name, :to => 'tree.klass.connection'

      def self_and_descendants(node, &block)
        traverse_down(node) do
          descendants_scope(node.ordered_tree_node, &block)
        end
      end

      def descendants(node, &block)
        traverse_down(node) do
          scope = self_and_descendants(node, &block)
          scope.where(scope.table[columns.id].not_eq(node.id))
        end
      end

      def self_and_ancestors(node, &block)
        traverse_up(node, [node]) do
          ancestors_scope(node.ordered_tree_node, &block)
        end
      end

      def ancestors(node, &block)
        traverse_up(node) do
          scope = self_and_ancestors(node, &block)
          scope.where(scope.table[columns.id].not_eq(node.id))
        end
      end

      private
      def traverse_down(node)
        if node && node.persisted?
          yield
        else
          none
        end
      end

      # Yields to block if record is persisted and its parent was not changed.
      # Returns empty scope (or scope with +including+ records) if record is root.
      # Otherwise recursively fetches ancestors and returns preloaded relation.
      def traverse_up(node, including = [])
        return none unless node

        if can_traverse_up?(node)
          if node.ordered_tree_node.has_parent?
            yield
          else
            including.empty? ? none : preloaded(including)
          end
        else
          preloaded(persisted_ancestors(node) + including)
        end
      end

      # Generates scope that traverses tree down to deep, starting from given +scope+
      def descendants_scope(node, &block)
        node.scope.
        extending(Relation::Recursive).
        connect_by(scope_columns_hash.merge(columns.id => columns.parent)).
          start_with(node.to_relation) do |start|
            start.select(positions_array.as(positions_alias))
          end.
          with_recursive do |descendants|
            descendants.select(positions_array.prepend(positions_alias))
          end.
          with_recursive(&block).
        reorder("#{positions_alias} ASC")
      end

      # Generates scope that traverses tree up to root, starting from given +scope+
      def ancestors_scope(node, &block)
        traverse = node.scope.
          extending(Relation::Recursive).
          connect_by(scope_columns_hash.merge(columns.parent => columns.id)).
          start_with(node.to_relation).
          with_recursive(&block)

        if columns.depth?
          traverse.start_with { |start| start.select depth }
          traverse.with_recursive { |ancestors| ancestors.select depth }
          traverse.reorder depth.asc
        else
          traverse.start_with { |start| start.select Arel.sql('0').as('_depth') }
          traverse.with_recursive { |ancestors| ancestors.select ancestors.previous['_depth'] - 1 }
          traverse.reorder('_depth ASC')
        end
      end

      def attribute(name)
        @tree.klass.arel_table[name]
      end

      def depth
        attribute(columns.depth)
      end

      def positions_array
        Arel::Nodes::PostgresArray.new(attribute(columns.position))
      end

      def positions_alias
        Arel.sql('_positions')
      end

      def can_traverse_up?(node)
        node.persisted? && !node.ordered_tree_node.parent_id_changed?
      end

      # Recursively fetches node's parents until one of them will be persisted.
      # Returns persisted ancestor and array of non-persistent ancestors
      def persisted_ancestors(node)
        queue = []

        parent = node

        while (parent = parent.parent)
          break if parent && parent.persisted?

          queue.unshift(parent)
        end

        ancestors(parent) + [parent].compact + queue
      end

      def scope_columns_hash
        Hash[tree.columns.scope.map { |x| [x, x] }]
      end
    end # class PostgreSQL
  end # module Adapters
end # module ActsAsOrderedTree