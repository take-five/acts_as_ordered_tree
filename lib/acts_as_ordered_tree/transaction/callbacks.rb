require 'active_support/callbacks'

module ActsAsOrderedTree
  module Transaction
    module Callbacks
      def self.extended(base)
        base.send(:include, ActiveSupport::Callbacks)
        base.define_callbacks :transaction
      end

      # @todo maybe :on option will be useful?
      def before(filter, *options, &block)
        set_callback :transaction, :before, filter, *options, &block
      end

      def after(filter, *options, &block)
        set_callback :transaction, :after, filter, *options, &block
      end

      def around(filter, *options, &block)
        set_callback :transaction, :around, filter, *options, &block
      end
    end
  end
end