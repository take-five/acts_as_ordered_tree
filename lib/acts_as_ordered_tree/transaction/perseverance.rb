# coding: utf-8

require 'acts_as_ordered_tree/persevering_transaction'

module ActsAsOrderedTree
  module Transaction
    # This module provides deadlock handling functionality
    #
    # @api private
    module Perseverance
      # Starts persevering transaction
      def transaction(&block)
        PerseveringTransaction.new(connection).start(&block)
      end
    end # module Perseverance
  end # module Transaction
end # module ActsAsOrderedTree