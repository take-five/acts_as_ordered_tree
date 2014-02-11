# coding: utf-8

require 'acts_as_ordered_tree/transaction/save'

module ActsAsOrderedTree
  module Transaction
    # Create transaction (for new records only)
    # @api private
    class Create < Save
      before :set_counter_cache, :if => 'klass.children_counter_cache_column'
      before :increment_lower_positions, :unless => :push_to_bottom?
      after  'to.increment_counter'

      # @todo увеличивать позицию до максимума, если создается корневой
      # @todo узел и до начала транзакции не было ни одного корневого узла

      private
      def set_counter_cache
        record[klass.children_counter_cache_column] = 0
      end

      def increment_lower_positions
        position_column = connection.quote_column_name(klass.position_column)

        to.lower.update_all(
          '%<position>s = %<position>s + 1' % {:position => position_column}
        )
      end
    end
  end
end