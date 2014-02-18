# coding: utf-8

require 'acts_as_ordered_tree/persevering_transaction'

module ActsAsOrderedTree
  class Tree
    # This module contains overridden :with_transaction_returning_status method
    # which wraps itself into PerseveringTransaction.
    #
    # This module is mixed in into Class after Class.acts_as_ordered_tree invocation.
    #
    # @api private
    module Perseverance
      def with_transaction_returning_status
        PerseveringTransaction.new(self.class.connection).start { super }
      end
    end
  end
end