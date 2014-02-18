# coding: utf-8

require 'acts_as_ordered_tree/transaction/base'
require 'acts_as_ordered_tree/transaction/dsl'

module ActsAsOrderedTree
  module Transaction
    class Destroy < Base
      include DSL

      attr_reader :from

      before 'trigger_callback(:before_remove, from.parent)'

      after :decrement_lower_positions
      after 'from.decrement_counter'
      after 'trigger_callback(:after_remove, from.parent)'

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position] from from which position given +node+ is destroyed
      def initialize(node, from)
        super(node)
        @from = from
      end

      private
      def decrement_lower_positions
        from.lower.update_all set position => position - 1
      end
    end
  end
end