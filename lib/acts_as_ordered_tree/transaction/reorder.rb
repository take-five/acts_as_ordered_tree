# coding: utf-8

require 'acts_as_ordered_tree/transaction/update'

module ActsAsOrderedTree
  module Transaction
    class Reorder < Update
      finalize

      protected
      # if we reorder node then we cannot put it to position higher than highest
      def push_to_bottom
        to.position = highest_position.zero? ? 1 : highest_position
      end

      private
      def update_scope
        to.siblings.where(positions_range)
      end

      def update_values
        { position => position_value }
      end

      def positions_range
        position.in([from.position, to.position].min..[from.position, to.position].max)
      end

      def position_value
        expr = switch.
            when(position == from.position).then(to.position).
            else(position)

        if to.position > from.position
          expr.when(positions_range).then(position - 1)
        else
          expr.when(positions_range).then(position + 1)
        end
      end
    end # class Reorder
  end # module Transaction
end # module ActsAsOrderedTree