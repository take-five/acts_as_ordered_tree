# coding: utf-8

require 'acts_as_ordered_tree/persevering_transaction'

module ActsAsOrderedTree
  # This module contains overridden :with_transaction_returning_status method
  # which wraps itself into PerseveringTransaction
  module Perseverance
    def with_transaction_returning_status
      PerseveringTransaction.new(self.class.connection).start { super }
    end
  end
end