# coding: utf-8

require 'acts_as_ordered_tree/transaction/save'
require 'acts_as_ordered_tree/dsl'

module ActsAsOrderedTree
  module Transaction
    # Create transaction (for new records only)
    # @api private
    class Create < Save
      include ActsAsOrderedTree::DSL

      before :push_to_bottom_after_commit, :if => 'push_to_bottom? && to.root?'
      before :set_counter_cache, :if => 'klass.children_counter_cache_column'
      before :increment_lower_positions, :unless => :push_to_bottom?
      after  'to.increment_counter'

      private
      def set_counter_cache
        record[klass.children_counter_cache_column] = 0
      end

      def increment_lower_positions
        to.lower.update_all set position => position + 1
      end

      # If record was created as root there is a chance that position will collide,
      # but this callback will force record to placed at the bottom of tree.
      #
      # Yep, concurrency is a tough thing.
      #
      # @see https://github.com/take-five/acts_as_ordered_tree/issues/24
      def push_to_bottom_after_commit
        transaction.after_commit do
          connection.logger.debug { "Forcing new record (id=#{record.id}, position=#{node.position}) to be placed to bottom" }

          connection.transaction do
            # lock new siblings
            to.siblings.lock.reload

            if positions_collided?
              update_created set position => siblings.select(coalesce(max(position), 0) + 1)
            end
          end
        end
      end

      # Checks if there is +position_column+ collision within new parent
      def positions_collided?
        to.siblings.where(id.not_eq(record.id).and(position.eq(to.position))).exists?
      end

      def update_created(*args)
        to.siblings.where(id.eq(record.id)).update_all(*args)
      end

      def siblings
        to.siblings.where(id.not_eq(record.id))
      end
    end # class Create
  end # module Transaction
end # module ActsAsOrderedTree