# coding: utf-8

require 'active_support/core_ext/module/aliasing'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/persevering_transaction'
require 'acts_as_ordered_tree/transaction/factory'

module ActsAsOrderedTree
  class Node
    # This module provides node with movement functionality
    #
    # Methods:
    # * move_to_root
    # * move_left (move_higher)
    # * move_right (move_lower)
    # * move_to_left_of (move_to_above_of)
    # * move_to_right_of (move_to_bottom_of)
    # * move_to_child_of
    # * move_to_child_with_index
    # * move_to_child_with_position
    module Movements
      # Transform node into root node
      def move_to_root
        movement do |to|
          to.position = record.root? ? position : nil
        end
      end

      # Swap node with higher sibling
      def move_higher
        movement do |to|
          to.parent_id = parent_id
          to.position = position - 1
        end
      end
      alias_method :move_left, :move_higher

      # Swap node with lower sibling
      def move_lower
        movement do |to|
          to.parent_id = parent_id
          to.position = position + 1
        end
      end
      alias_method :move_right, :move_lower

      # Move node to above(left) of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_above_of(node)
        movement(node) do |to, target|
          lower = target.parent_id == parent_id && target.position > position

          to.parent_id = target.parent_id
          to.position = lower ? target.position - 1 : target.position
        end
      end
      alias_method :move_to_left_of, :move_to_above_of

      # Move node to bottom (right) of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_bottom_of(node)
        movement(node) do |to, target|
          lower = target.parent_id == parent_id && target.position > position

          to.parent_id = target.parent_id
          to.position = lower ? target.position : target.position + 1
        end
      end
      alias_method :move_to_right_of, :move_to_bottom_of

      # Move node to child of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_child_of(node)
        if node
          movement(node) do |to, target|
            # don't do anything if new parent is the same
            return true if target.id == parent_id

            to.parent_id = target.id
            to.position = nil
          end
        else
          move_to_root
        end
      end

      # Move node to child of another node with specified index (which may be negative)
      #
      # @param [ActiveRecord::Base, Fixnum] node
      # @param [#to_i] index
      def move_to_child_with_index(node, index)
        index = index.to_i

        if index >= 0
          move_to_child_with_position node, index + 1
        elsif node
          movement(node) do |to, target|
            to.parent_id = target.id
            to.position = target.children.size + index + 1
          end
        else
          move_to_child_with_position nil, scope.roots.size + index + 1
        end
      end

      # Move node to child of another node with specified position
      #
      # @param [ActiveRecord::Base, Fixnum] node
      # @param [Integer, nil] position
      def move_to_child_with_position(node, position)
        movement(node) do |to, target|
          to.parent_id = target.try(:id)
          to.position = position
        end
      end

      private
      def movement(target = nil, &block)
        Movement.start(self, target, &block)
      end

      class Movement
        def self.start(node, target, &block)
          new(node, target, &block).start
        end

        # @param [ActsAsOrderedTree::Node] node moved node
        # @param [ActiveRecord::Base, #to_i]
        def initialize(node, target, &block)
          @node = node
          @_target = target

          @from = Position.new(node, node.parent_id, node.position)
          @to = Position.new(node, nil, nil)
          @transition = Position::Transition.new(@from, @to)

          @block = block
        end

        def start
          persevering do
            @block.call(@to, target) if @block

            return false unless valid?

            transaction.start { true }
          end
        end

        private
        def valid?
          @node.record != target.try(:record) && @to.valid?
        end

        def transaction
          @transaction ||= Transaction::Factory.create_from_transition(@node, @transition)
        end

        def persevering
          PerseveringTransaction.new(@node.record.class.connection).start do
            @node.reload

            yield
          end
        end

        def target
          @target ||= @_target && @node.scope.lock.find(@_target).ordered_tree_node
        end
      end # class Movement
    end # module Movements
  end # class Node
end # module ActsAsOrderedTree