# coding: utf-8

module ActsAsOrderedTree
  module Transaction
    # Null transaction, does nothing but delegates to caller
    class Passthrough
      def start(&block)
        block.call if block_given?
      end
    end
  end
end