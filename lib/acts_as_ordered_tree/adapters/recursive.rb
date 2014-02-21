# coding: utf-8

require 'acts_as_ordered_tree/adapters/abstract'

module ActsAsOrderedTree
  module Adapters
    # Recursive adapter implements tree traversal in pure Ruby.
    class Recursive < Abstract
      def self_and_ancestors(node, &block)
        return none unless node

        preloaded_starting_with(node) { fetch_ancestors(node, &block) + [node] }
      end

      def ancestors(node, &block)
        nodes = fetch_ancestors(node, &block)

        if nodes.any?
          preloaded_starting_with(node) { nodes }
        else
          none
        end
      end

      def descendants(node, &block)
        return none unless node.persisted?

        children = block ? block.call(node.association(:children).scope) : node.children

        preloaded_starting_with(node) do
          children.map { |n| [n] + n.descendants(&block) }.reduce([], :+)
        end
      end

      def self_and_descendants(node, &block)
        return none unless node.persisted?

        preloaded_starting_with(node) { [node] + descendants(node, &block) }
      end

      private
      def parent(node, &block)
        if block then
          block.call(node.association(:parent).scope).first
        else
          node.parent
        end
      end

      def fetch_ancestors(node, &block)
        if node && (parent = parent(node, &block))
          fetch_ancestors(parent, &block) + [parent]
        else
          []
        end
      end

      def preloaded_starting_with(start_record, &records)
        preloaded(records.call).extending(StartWith).start_record(start_record)
      end

      # It is not recommended to use #start_with with this adapter, but
      # it can be used in simple cases.
      #
      # @api private
      module StartWith
        def start_with(scope = nil, &block)
          return self unless @start_record && (scope || block)

          scope ||= block.call(where(klass.primary_key => @start_record.id))

          if scope.exists?
            self
          else
            none
          end
        end

        def start_record(record)
          @start_record = record if record.persisted?

          self
        end
      end
      private_constant :StartWith
    end # class Recursive
  end # module Adapters
end # module ActsAsOrderedTree