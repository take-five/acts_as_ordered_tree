module ActsAsOrderedTree
  class Tree
    # @deprecated Use `ordered_tree.columns` object
    module DeprecatedColumnsAccessors
      class << self
        # @api private
        def deprecated_method(method, delegate)
          define_method(method) do
            ActiveSupport::Deprecation.warn("#{name}.#{method} is deprecated in favor of #{name}.ordered_tree.columns.#{delegate}", caller(1))

            ordered_tree.columns.send(delegate)
          end
        end
        private :deprecated_method
      end

      deprecated_method :parent_column, :parent
      deprecated_method :position_column, :position
      deprecated_method :depth_column, :depth
      deprecated_method :children_counter_cache_column, :counter_cache
      deprecated_method :scope_column_name, :scope
    end
  end
end