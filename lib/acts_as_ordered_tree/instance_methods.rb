# coding: utf-8

require 'acts_as_ordered_tree/node'
require 'acts_as_ordered_tree/transaction/factory'
require 'acts_as_ordered_tree/deprecate'

module ActsAsOrderedTree
  module InstanceMethods
    extend Deprecate

    delegate :root?,
             :leaf?,
             :has_children?,
             :has_parent?,
             :first?,
             :last?,
             :is_descendant_of?,
             :is_or_is_descendant_of?,
             :is_ancestor_of?,
             :is_or_is_ancestor_of?,
             :to => :ordered_tree_node

    delegate :move_to_root,
             :move_higher,
             :move_left,
             :move_lower,
             :move_right,
             :move_to_above_of,
             :move_to_left_of,
             :move_to_bottom_of,
             :move_to_right_of,
             :move_to_child_of,
             :move_to_child_with_index,
             :move_to_child_with_position,
             :to => :ordered_tree_node

    delegate :ancestors,
             :self_and_ancestors,
             :descendants,
             :self_and_descendants,
             :root,
             :siblings,
             :self_and_siblings,
             :left_siblings,
             :higher_items,
             :left_sibling,
             :higher_item,
             :left_sibling=,
             :left_sibling_id=,
             :higher_item=,
             :higher_item_id=,
             :right_siblings,
             :lower_items,
             :right_sibling,
             :lower_item,
             :right_sibling=,
             :right_sibling_id=,
             :lower_item=,
             :lower_item_id=,
             :to => :ordered_tree_node

    delegate :level, :to => :ordered_tree_node

    # Returns ordered tree node - an object which maintains tree integrity.
    # WARNING: THIS METHOD IS NOT THREAD SAFE!
    # Though I'm not sure if it can cause any problems.
    #
    # @return [ActsAsOrderedTree::Node]
    def ordered_tree_node
      @ordered_tree_node ||= ActsAsOrderedTree::Node.new(self)
    end

    # Insert the item at the given position (defaults to the top position of 1).
    # +acts_as_list+ compatibility
    #
    # @deprecated
    deprecated_method :insert_at, :move_to_child_with_position do |position = 1|
      move_to_child_with_position(parent, position)
    end

    # Returns +true+ if it is possible to move node to left/right/child of +target+.
    #
    # @param [ActiveRecord::Base] target
    # @deprecated
    deprecated_method :move_possible? do |target|
      ordered_tree_node.same_scope?(target) &&
          !ordered_tree_node.is_or_is_ancestor_of?(target)
    end

    # Returns true if node contains any children.
    #
    # @deprecated
    deprecated_method :branch?, :has_children?

    # Returns true is node is not a root node.
    #
    # @deprecated
    deprecated_method :child?, :has_parent?

    private
    # Around callback that starts ActsAsOrderedTree::Transaction
    def save_ordered_tree_node(&block)
      Transaction::Factory.create(ordered_tree_node).start(&block)
    end

    # Around callback that starts ActsAsOrderedTree::Transaction
    def destroy_ordered_tree_node(&block)
      Transaction::Factory.create(ordered_tree_node, true).start(&block)
    end
  end # module InstanceMethods
end # module ActsAsOrderedTree
