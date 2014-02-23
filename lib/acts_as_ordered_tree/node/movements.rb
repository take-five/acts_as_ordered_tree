# coding: utf-8

require 'active_support/core_ext/module/aliasing'

require 'acts_as_ordered_tree/node/movement'

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
          to.parent = nil
        end
      end

      # Swap node with higher sibling
      def move_higher
        movement { self.position -= 1 }
      end
      alias_method :move_left, :move_higher

      # Swap node with lower sibling
      def move_lower
        movement { self.position += 1 }
      end
      alias_method :move_right, :move_lower

      # Move node to above(left) of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_above_of(node)
        movement(node, :strict => true) do |to|
          lower = to.target.parent_id == parent_id && to.target.position > position

          to.parent = to.target.parent_id
          to.position = lower ? to.target.position - 1 : to.target.position
        end
      end
      alias_method :move_to_left_of, :move_to_above_of

      # Move node to bottom (right) of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_bottom_of(node)
        movement(node, :strict => true) do |to|
          lower = to.target.parent_id == parent_id && to.target.position > position

          to.parent = to.target.parent_id
          to.position = lower || to.target.record == record ? to.target.position : to.target.position + 1
        end
      end
      alias_method :move_to_right_of, :move_to_bottom_of

      # Move node to child of another node
      #
      # @param [ActiveRecord::Base, #to_i] node may be another record of ID
      def move_to_child_of(node)
        if node
          movement(node) do |to|
            to.parent = node
            to.position = nil if parent_id_changed?
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
          movement(node, :strict => true) do |to|
            to.parent = node
            to.position = to.target.children.size + index + 1
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
        movement(node) do |to|
          to.parent = node
          to.position = position
        end
      end

      private
      def movement(target = nil, options = {}, &block)
        Movement.new(self, target, options, &block).start
      end
    end # module Movements
  end # class Node
end # module ActsAsOrderedTree