# coding: utf-8

require 'acts_as_ordered_tree/transaction/base'

module ActsAsOrderedTree
  module Transaction
    class Destroy < Base
      attr_reader :from

      after :decrement_lower_positions
      after :decrement_counter_cache

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position] from from which position given +node+ is destroyed
      def initialize(node, from)
        super(node)
        @from = from
      end

      private
      def decrement_counter_cache
        if (column = klass.children_counter_cache_column) && from.parent_id
          klass.decrement_counter(column, from.parent_id)
        end
      end

      def decrement_lower_positions
        position_column = connection.quote_column_name(klass.position_column)

        from.lower.update_all(
            '%<position>s = %<position>s - 1' % {:position => position_column}
        )
      end
    end
  end
end