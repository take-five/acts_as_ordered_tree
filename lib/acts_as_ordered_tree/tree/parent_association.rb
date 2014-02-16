# coding: utf-8

require 'acts_as_ordered_tree/tree/association'

module ActsAsOrderedTree
  class Tree
    class ParentAssociation < Association
      # create parent association
      #
      # we cannot use native :counter_cache callbacks because they suck! :(
      # they act like this:
      #   node.parent = new_parent # and here counters are updated, outside of transaction!
      def build
        klass.belongs_to(:parent, options)
      end

      private
      def options
        Hash[
          :class_name => class_name,
          :foreign_key => tree.columns.parent,
          :inverse_of => inverse_of
        ]
      end

      def inverse_of
        :children unless tree.options[:polymorphic]
      end
    end # class ParentAssociation
  end # class Tree
end # module ActsAsOrderedTree