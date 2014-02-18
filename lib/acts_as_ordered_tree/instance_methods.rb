# coding: utf-8

require 'acts_as_ordered_tree/node'
require 'acts_as_ordered_tree/transaction/factory'

module ActsAsOrderedTree
  module InstanceMethods
    delegate :root?,
             :leaf?,
             :branch?,
             :child?,
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
             :right_siblings,
             :lower_items,
             :right_sibling,
             :lower_item,
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
    def insert_at(position = 1)
      ActiveSupport::Deprecation.warn "#{self.class.name}#insert_at is "\
        'deprecated and will be removed in acts_as_ordered_tree-2.1, '\
        'use #move_to_child_with_position instead', caller(1)

      move_to_child_with_position(parent, position)
    end

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
