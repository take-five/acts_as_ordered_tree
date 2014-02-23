require 'active_support/callbacks'

module ActsAsOrderedTree
  module Transaction
    module Callbacks
      def self.extended(base)
        base.send(:include, ActiveSupport::Callbacks)
        base.define_callbacks :transaction, :delegate
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

      def before_delegate(filter, *options, &block)
        set_callback :delegate, :before, filter, *options, &block
      end

      # This method should be called in concrete transaction classes to prevent
      # race conditions in multi-threaded environments.
      #
      # @api private
      def finalize
        finalize_callbacks :transaction
        finalize_callbacks :delegate
      end

      private
      Compatibility.version '< 3.2.0' do
        def finalize_callbacks(kind)
          __define_runner(kind)
        end
      end

      Compatibility.version '>= 3.2.0', '< 4.0.0' do
        def finalize_callbacks(kind)
          __reset_runner(kind)

          object = allocate

          name = __callback_runner_name(nil, kind)
          unless object.respond_to?(name, true)
            str = object.send("_#{kind}_callbacks").compile(nil, object)
            class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
              def #{name}() #{str} end
              protected :#{name}
            RUBY_EVAL
          end
        end
      end

      Compatibility.version '>= 4.0.0', '< 4.1.0' do
        def finalize_callbacks(kind)
          __define_callbacks(kind, allocate)
        end
      end

      # Rails 4.1 is thread safe
      Compatibility.version '>= 4.1.0' do
        def finalize_callbacks(kind) end
      end
    end # module Callbacks
  end # module Transaction
end # module ActsAsOrderedTree