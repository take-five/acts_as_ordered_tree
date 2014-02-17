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
          descendants_scope(node.ordered_tree_node.to_relation, &block)
        end
      end

      def descendants(node, &block)
        traverse_down(node) do
          descendants_scope(node.association(:children).scope, &block)
        end
      end

      def self_and_ancestors(node, &block)
        traverse_up(node, [node]) do
          ancestors_scope(node.ordered_tree_node.to_relation, &block)
        end
      end

      def ancestors(node, &block)
        traverse_up(node) do
          ancestors_scope(node.association(:parent).scope, &block)
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
          if node.ordered_tree_node.child?
            yield
          else
            including.empty? ? none : preloaded(including)
          end
        else
          preloaded(persisted_ancestors(node) + including)
        end
      end

      # Generates scope that traverses tree down to deep, starting from given +scope+
      def descendants_scope(scope, &block)
        scope.
        extending(Relation::Recursive).
        recursive_join(columns.id => columns.parent, &block).
          start_with do |start|
            start.select(positions_array.as(positions_alias))
          end.
          recursive do |descendants|
            descendants.select(positions_array.prepend(positions_alias))
          end.
        reorder("#{positions_alias} ASC")
      end

      # Generates scope that traverses tree up to root, starting from given +scope+
      def ancestors_scope(scope, &block)
        traverse = scope.
          extending(Relation::Recursive).
          recursive_join(columns.parent => columns.id, &block)

        if columns.depth?
          traverse.start_with { |start| start.select depth }
          traverse.recursive { |ancestors| ancestors.select depth }
          traverse.reorder depth.asc
        else
          traverse.start_with { |start| start.select Arel.sql('0').as('_depth') }
          traverse.recursive { |ancestors| ancestors.select ancestors.previous['_depth'] - 1 }
          traverse.reorder('_depth ASC')
        end
      end

      def attribute(name)
        @tree.klass.arel_table[name]
      end

      def depth
        attribute(columns.depth)
      end

      def array(*values)
        Arel::Nodes::PostgresArray.new(values)
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
    end # class PostgreSQL
  end # module Adapters
end # module ActsAsOrderedTree