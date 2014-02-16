# coding: utf-8

require 'acts_as_ordered_tree/transaction/base'

module ActsAsOrderedTree
  module Transaction
    class Save < Base
      attr_reader :to

      before 'to.lock!'
      before :set_scope!, :if => 'to.parent?'
      before :push_to_bottom, :if => :push_to_bottom?
      before 'to.position = 1', :if => 'to.position <= 0'

      around :copy_attributes

      after 'node.reload'

      # @param [ActsAsOrderedTree::Node] node
      # @param [ActsAsOrderedTree::Position] to to which position given +node+ is saved
      def initialize(node, to)
        super(node)
        @to = to
      end

      protected
      # Copies parent_id, position and depth from destination to record
      def copy_attributes
        record.parent = to.parent
        node.position = to.position
        node.depth = to.depth if tree.columns.depth?

        yield
      end

      # Returns highest position within node's siblings
      def highest_position
        @highest_position ||= to.siblings.maximum(tree.columns.position) || 0
      end

      # Should be fired when given position is empty
      def push_to_bottom
        to.position = highest_position + 1
      end

      # Returns true if record should be pushed to bottom of list
      def push_to_bottom?
        to.position.blank? ||
            position_out_of_bounds?
      end

      private
      def set_scope!
        tree.columns.scope.each do |column|
          record[column] = to.parent[column]
        end

        nil
      end

      def position_out_of_bounds?
        to.position > highest_position
      end
    end # class Save
  end # module Transaction
end # module ActsAsOrderedTree