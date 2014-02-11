# coding: utf-8

require 'active_support/core_ext/object/with_options'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/transaction/save'
require 'acts_as_ordered_tree/dsl'

module ActsAsOrderedTree
  module Transaction
    # Update transaction includes Move and Reorder
    #
    # @abstract
    # @api private
    class Update < Save
      include ActsAsOrderedTree::DSL

      attr_reader :from, :transition

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position::Transition] transition
      def initialize(node, transition)
        @transition = transition
        @from = transition.from

        super(node, transition.to)
      end
    end
  end
end