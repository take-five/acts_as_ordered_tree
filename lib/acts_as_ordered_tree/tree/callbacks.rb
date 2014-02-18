# coding: utf-8

require 'active_support/core_ext/hash/slice'

module ActsAsOrderedTree
  class Tree
    # Tree callbacks storage
    #
    # @example
    #   MyModel.ordered_tree.callbacks.before_add(parent, child)
    #
    # @api private
    class Callbacks
      VALID_KEYS = :before_add,
                   :after_add,
                   :before_remove,
                   :after_remove

      def initialize(klass, options)
        @klass = klass
        @callbacks = {}

        options.slice(*VALID_KEYS).each do |k, v|
          @callbacks[k] = v if v
        end
      end

      def to_h
        @callbacks.dup
      end

      # generate accessors and predicates
      VALID_KEYS.each do |method|
        define_method(method) do |parent, record| # def before_add(parent, record)
          run_callbacks(method, parent, record)
        end
      end

      private
      def run_callbacks(method, parent, record)
        callback = callback_for(method)

        case callback
          when Symbol
            parent.send(callback, record)
          when Proc
            callback.call(parent, record)
          when nil, false
            # do nothing
          else
            # parent.before_add(record)
            callback.send(method, parent, record)
        end
      end

      def callback_for(method)
        @callbacks[method]
      end
    end # class Callbacks
  end # class Tree
end # module ActsAsOrderedTree