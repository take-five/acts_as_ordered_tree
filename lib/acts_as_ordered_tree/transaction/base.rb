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

      delegate :record, :tree, :to => :node
      delegate :connection, :to => :klass

      # @param [ActsAsOrderedTree::Node] node
      def initialize(node)
        @node = node
      end

      # Start persevering transaction, which will restart on deadlock
      def start(&block)
        transaction.start do
          run_callbacks(:transaction, &block)
        end
      end

      protected
      def klass
        record.class
      end

      # Returns underlying transaction object
      def transaction
        @transaction ||= PerseveringTransaction.new(connection)
      end

      # Trigger tree callback (before_add, after_add, before_remove, after_remove)
      def trigger_callback(kind, owner)
        tree.callbacks.send(kind, owner, record) if owner.present?
      end
    end
  end
end