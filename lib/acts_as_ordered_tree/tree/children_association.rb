# coding: utf-8

require 'acts_as_ordered_tree/compatibility'
require 'acts_as_ordered_tree/tree/association'
require 'acts_as_ordered_tree/relation/iterable'

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
          :extend => [extension, Relation::Iterable].compact
        ]
      end

      def inverse_of
        :parent unless tree.options[:polymorphic]
      end

      # rails 4.x scope for has_many association
      def scope
        assoc_scope = method(:association_scope)
        join_scope = method(:join_association_scope)

        ->(join_or_parent) {
          if join_or_parent.is_a?(ActiveRecord::Associations::JoinDependency::JoinAssociation)
            join_scope[join_or_parent]
          elsif join_or_parent.is_a?(ActiveRecord::Base)
            assoc_scope[join_or_parent]
          else
            where(nil)
          end.extending(Relation::Iterable)
        }
      end

      # Rails 3.x :conditions options for has_many association
      def conditions
        return nil unless tree.columns.scope?

        assoc_scope = method(:association_scope)
        join_scope = method(:join_association_scope)

        Proc.new do |join_association|
          conditions = if join_association.is_a?(ActiveRecord::Associations::JoinDependency::JoinAssociation)
            join_scope[join_association]
          elsif self.is_a?(ActiveRecord::Base)
            assoc_scope[self]
          else
            where(nil)
          end.where_values.reduce(:and)

          conditions.try(:to_sql)
        end
      end

      def order
        tree.columns.position
      end

      def extension
        if tree.columns.counter_cache?
          CounterCache
        end
      end

      def join_association_scope(join_association)
        parent = join_association.respond_to?(:parent) ?
            join_association.parent.table :
            join_association.base_klass.arel_table

        child = join_association.table

        conditions = tree.columns.scope.map { |column| parent[column].eq child[column] }.reduce(:and)

        klass.unscoped.where(conditions)
      end

      def association_scope(owner)
        owner.ordered_tree_node.scope.order(tree.columns.position)
      end
    end # class ChildrenAssociation
  end # class Tree
end # module ActsAsOrderedTree