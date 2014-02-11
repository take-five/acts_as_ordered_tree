# coding: utf-8

require 'acts_as_ordered_tree/transaction/update'

module ActsAsOrderedTree
  module Transaction
    class Reorder < Update
      with_options :if => 'transition.reorder?' do |reorder|
        reorder.around :callbacks
        reorder.before :update_tree
      end

      protected
      # if we reorder node then we cannot put it to position higher than highest
      def push_to_bottom
        to.position = highest_position.zero? ? 1 : highest_position
      end

      private
      def callbacks(&block)
        record.run_callbacks(:reorder, &block)
      end

      def update_tree
        expr = switch.
            when(position == from.position).then(to.position).
            else(position)

        positions_range = position.in([from.position, to.position].min..[from.position, to.position].max)

        if to.position > from.position
          expr.when(positions_range).then(position - 1)
        else
          expr.when(positions_range).then(position + 1)
        end

        node.siblings.where(positions_range).update_all set position => expr
      end
    end
  end
end