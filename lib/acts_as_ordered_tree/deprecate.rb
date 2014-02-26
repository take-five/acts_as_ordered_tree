# coding: utf-8

module ActsAsOrderedTree
  # @api private
  module Deprecate
    NEXT_VERSION = '2.1'

    def deprecated_method(method, replacement = nil, &block)
      define_method(method) do |*args, &method_block|
        message = "#{self.class.name}##{__method__} is "\
                  "deprecated and will be removed in acts_as_ordered_tree-#{NEXT_VERSION}"
        message << ", use ##{replacement} instead" if replacement

        ActiveSupport::Deprecation.warn message, caller(2)

        if block
          instance_exec(*args, &block)
        elsif replacement
          __send__(replacement, *args, &method_block)
        end
      end
    end
  end
end