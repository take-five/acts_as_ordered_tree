# coding: utf-8

require 'active_support/core_ext/object/with_options'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/transaction/save'
require 'acts_as_ordered_tree/transaction/dsl'

module ActsAsOrderedTree
  module Transaction
    # Update transaction includes Move and Reorder
    #
    # @abstract
    # @api private
    class Update < Save
      include DSL

      attr_reader :from, :transition

      before_delegate :reset_node!

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position::Transition] transition
      def initialize(node, transition)
        @transition = transition
        @from = transition.from

        super(node, transition.to)
      end

      private
      def reset_node!
        node.reset_position!
        node.reset_parent_id!
        node.reload
      end
    end
  end
end