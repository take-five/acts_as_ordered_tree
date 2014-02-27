# coding: utf-8

require 'active_support/core_ext/object/with_options'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/transaction/save'
require 'acts_as_ordered_tree/transaction/dsl'

module ActsAsOrderedTree
  module Transaction
    # Update transaction includes Move and Reorder
    #
    # @abstract
    # @api private
    class Update < Save
      include DSL

      attr_reader :from, :transition

      around :update_tree

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position::Transition] transition
      def initialize(node, transition)
        @transition = transition
        @from = transition.from

        super(node, transition.to)
      end

      protected
      def update_tree
        callbacks = transition.reorder? ? :reorder : :move

        record.run_callbacks(callbacks) do
          record.hook_update do |update|
            update.scope = update_scope
            update.values = update_values.merge(changed_attributes)

            yield
          end
        end
      end

      def update_scope
        # implement in successors
      end

      def update_values
        # implement in successors
      end

      private
      # Returns hash of UPDATE..SET expressions for each
      # changed record attribute (except tree attributes)
      #
      # @return [Hash<String => Arel::Nodes::Node>]
      def changed_attributes
        changed_attributes_names.each_with_object({}) do |attr, hash|
          hash[attr] = attribute_value(attr)
        end
      end

      def attribute_value(attr)
        attr_value = record.read_attribute(attr)
        quoted = record.class.connection.quote(attr_value)

        switch.
            when(id == record.id).then(Arel.sql(quoted)).
            else(attribute(attr))
      end

      def changed_attributes_names
        record.changed - (tree.columns.to_a - tree.columns.scope)
      end
    end
  end
end