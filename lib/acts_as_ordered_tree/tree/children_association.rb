# coding: utf-8

require 'acts_as_ordered_tree/compatibility'
require 'acts_as_ordered_tree/tree/association'

module ActsAsOrderedTree
  class Tree
    # @api private
    class ChildrenAssociation < Association
      # CounterCache extensions will allow to use cached value
      #
      # @api private
      module CounterCache
        def size
          ordered_tree_node.parent_id_changed? ? super : ordered_tree_node.counter_cache
        end

        def empty?
          size == 0
        end

        private
        def ordered_tree_node
          @association.owner.ordered_tree_node
        end
      end

      # Builds association object
      def build
        Compatibility.version '< 4.0.0' do
          opts = options.merge(:conditions => conditions, :order => order)

          klass.has_many(:children, opts)
        end

        Compatibility.version '>= 4.0.0' do
          klass.has_many(:children, scope, options)
        end
      end

      private
      def options
        Hash[
          :class_name => class_name,
          :foreign_key => tree.columns.parent,
          :inverse_of => inverse_of,
          :dependent => :destroy,
          :extend => extension
        ]
      end

      def inverse_of
        :parent unless tree.options[:polymorphic]
      end

      def scope
        tree = self.tree

        ->(parent) { parent.ordered_tree_node.scope.order(tree.columns.position) }
      end

      # Generate :conditions options for Rails 3.x
      def conditions
        assoc_scope = scope
        proc { assoc_scope[self].where_values.reduce(:and).try(:to_sql) }
      end

      def order
        tree.columns.position
      end

      def extension
        if tree.columns.counter_cache?
          CounterCache
        end
      end
    end # class ChildrenAssociation
  end # class Tree
end # module ActsAsOrderedTree