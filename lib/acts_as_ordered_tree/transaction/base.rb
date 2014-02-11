# coding: utf-8

require 'acts_as_ordered_tree/persevering_transaction'
require 'acts_as_ordered_tree/transaction/callbacks'

module ActsAsOrderedTree
  module Transaction
    # Persevering transaction, which restarts on deadlock
    #
    # Here we have a tree of possible transaction types:
    #
    #   Base (abstract)
    #     Save (abstract)
    #       Create
    #       Update (abstract)
    #         Move
    #         Reorder
    #     Destroy
    #
    # @api private
    class Base
      extend Callbacks

      attr_reader :node

      delegate :record, :to => :node
      delegate :connection, :to => :klass

      # @param [ActsAsOrderedTree::Node] node
      def initialize(node)
        @node = node
      end

      # Start persevering transaction, which will restart on deadlock
      def start(&block)
        PerseveringTransaction.new(connection).start do
          run_callbacks :transaction, &block
        end
      end

      protected
      def klass
        record.class
      end
    end
  end
end