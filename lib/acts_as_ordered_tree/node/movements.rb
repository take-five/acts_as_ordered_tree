# coding: utf-8

require 'active_support/core_ext/module/aliasing'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/persevering_transaction'
require 'acts_as_ordered_tree/transaction/factory'

module ActsAsOrderedTree
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
  module Node::Movements
    # @api private
    def self.persevering(method)
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}_with_persevering(*args)
          persevering do
            #{method}_without_persevering(*args)
          end
        end
      RUBY

      alias_method_chain method, :persevering
    end

    # Transform node into root node
    def move_to_root
      move_to nil, record.root? ? position : nil
    end
    persevering :move_to_root

    # Swap node with higher sibling
    def move_higher
      move_to parent_id, position - 1
    end
    persevering :move_higher
    alias_method :move_left, :move_higher

    # Swap node with lower sibling
    def move_lower
      move_to parent_id, position + 1
    end
    persevering :move_lower
    alias_method :move_right, :move_lower

    # Move node to above(left) of another node
    #
    # @param [ActiveRecord::Base, #to_i] node may be another record of ID
    def move_to_above_of(node)
      with_target(node) do |target, lower|
        move_to target.parent_id, lower ? target.position - 1 : target.position
      end
    end
    persevering :move_to_above_of
    alias_method :move_to_left_of, :move_to_above_of

    # Move node to bottom (right) of another node
    #
    # @param [ActiveRecord::Base, #to_i] node may be another record of ID
    def move_to_bottom_of(node)
      with_target(node) do |target, lower|
        move_to target.parent_id, lower ? target.position : target.position + 1
      end
    end
    persevering :move_to_bottom_of
    alias_method :move_to_right_of, :move_to_bottom_of

    # Move node to child of another node
    #
    # @param [ActiveRecord::Base, #to_i] node may be another record of ID
    def move_to_child_of(node)
      if node
        persevering do
          with_target(node) do |target|
            move_to target.id, nil if target.id != parent_id
          end
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
        persevering do
          # @todo here 1 redundant query
          with_target(node) do |target|
            move_to_child_with_position node, target.children.size + index + 1
          end
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
      if node
        with_target(node) do |target|
          move_to target.id, position
        end
      else
        move_to nil, position
      end
    end
    persevering :move_to_child_with_position

    private
    def move_to(new_parent_id, new_position)
      from = Position.new(self, parent_id, position)
      to = Position.new(self, new_parent_id, new_position)

      # @todo maybe move it to transaction callbacks?
      return false unless to.valid?

      transition = Position::Transition.new(from, to)

      transaction = Transaction::Factory.create_from_transition(self, transition)
      transaction.start { true }
    end

    # @param [ActiveRecord::Base] node
    # @yield target, lower
    # @yieldparam [ActsAsOrderedTree::Node] target
    # @yieldparam [true, false] lower
    def with_target(node)
      # reload and lock target node
      target = scope.lock.find(node).ordered_tree_node
      # @todo yuck!
      to_lower = target.parent_id == parent_id && target.position > position

      yield target, to_lower if target.record != record
    end

    # Wraps block with persevering transaction
    def persevering
      PerseveringTransaction.new(record.class.connection).start do
        reload

        yield
      end
    end
  end
end