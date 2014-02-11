# coding: utf-8

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/transaction/create'
require 'acts_as_ordered_tree/transaction/destroy'
require 'acts_as_ordered_tree/transaction/move'
require 'acts_as_ordered_tree/transaction/passthrough'
require 'acts_as_ordered_tree/transaction/reorder'

module ActsAsOrderedTree
  module Transaction
    # @api private
    module Factory
      # Creates previous and current position objects for node
      # @api private
      class PositionFactory
        def initialize(node)
          @node = node
        end

        def previous
          Position.new @node, @node.parent_id_was, @node.position_was
        end

        def current
          Position.new @node, @node.parent_id, @node.position
        end

        def transition
          Position::Transition.new(previous, current)
        end
      end
      private_constant :PositionFactory

      # Creates proper transaction according to +node+
      #
      # @param [ActsAsOrderedTree::Node] node
      # @param [true, false] destroy set to true if node should be destroyed
      # @return [ActsAsOrderedTree::Transaction::Base]
      def create(node, destroy = false)
        pos = PositionFactory.new(node)

        case
          when destroy
            Destroy.new(node, pos.previous)
          when node.record.new_record?
            Create.new(node, pos.current)
          else
            create_from_transition(node, pos.transition)
        end
      end
      module_function :create

      def create_from_transition(node, transition)
        case
          when transition.movement?
            Move.new(node, transition)
          when transition.reorder?
            Reorder.new(node, transition)
          else
            Passthrough.new
        end
      end
      module_function :create_from_transition
    end
  end
end