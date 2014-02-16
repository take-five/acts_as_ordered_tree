# coding: utf-8

module ActsAsOrderedTree
  class Tree
    # Tree callbacks storage
    #
    # @example
    #   MyModel.ordered_tree.callbacks.before_add? # => false
    #   MyModel.ordered_tree
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
      VALID_KEYS.each do |k|
        define_method(k) do |owner, record| # def before_add(parent, record)
          if @callbacks.key?(k)
            raise NotImplementedError, "#{k} callbacks not implemented yet"
          end
        end

        # def before_add?() @callbacks.key?(:before_add) end
        define_method("#{k}?") do
          @callbacks.key?(k)
        end
      end
    end # class Callbacks
  end # class Tree
end # module ActsAsOrderedTree