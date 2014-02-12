# coding: utf-8

require 'acts_as_ordered_tree/node'
require 'acts_as_ordered_tree/relation/preloaded'
require 'acts_as_ordered_tree/relation/arrangeable'
require 'acts_as_ordered_tree/transaction/factory'

module ActsAsOrderedTree
  module InstanceMethods
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

    # Returns ordered tree node - an object which maintains tree integrity.
    # WARNING: THIS METHOD IS NOT THREAD SAFE!
    # Though I'm not sure if it can cause any problems.
    #
    # @return [ActsAsOrderedTree::Node]
    def ordered_tree_node
      @ordered_tree_node ||= ActsAsOrderedTree::Node.new(self)
    end

    # Returns true if this is a root node.
    def root?
      self[parent_column].nil?
    end

    # Returns true if this is the end of a branch.
    def leaf?
      persisted? && if children_counter_cache_column
        self[children_counter_cache_column] == 0
      else
        children.count == 0
      end
    end

    def branch?
      !leaf?
    end

    # Returns true is this is a child node
    def child?
      !root?
    end

    # Returns root (not really fast operation)
    def root
      root? ? self : parent.root
    end

    # Returns the array of all parents and self starting from root
    def self_and_ancestors
      # 1. recursively load ancestors
      nodes = []
      node = self

      while node
        nodes << node
        node = node.parent
      end

      # 2. first ancestor is a root
      nodes.reverse!

      ordered_tree_node.
          scope.
          extending(Relation::Arrangeable, Relation::Preloaded).
          records(nodes)
    end

    # Returns the array of all parents starting from root
    def ancestors
      records = self_and_ancestors - [self]

      scope = self_and_ancestors.where(arel[:id].not_eq(id))
      scope.records(records)
    end

    # Returns the array of all children of the parent, including self
    def self_and_siblings
      ordered_tree_node.scope.where(parent_column => self[parent_column]).reorder(arel[position_column].asc)
    end

    # Returns the array of all children of the parent, except self
    def siblings
      self_and_siblings.where(arel[:id].not_eq(id))
    end

    def level
      if depth_column
        # cached result becomes invalid when parent is changed
        if new_record? ||
            changed_attributes.include?(parent_column.to_s) ||
            self[depth_column].blank?
          self[depth_column] = compute_level
        else
          self[depth_column]
        end
      else
        compute_level
      end
    end

    # Returns a set of all of its children and nested children.
    # A little bit tricky. use RDBMS with recursive queries support (PostgreSQL)
    def descendants
      #self.class.where(:id => id).
      #    connect_by(:id => :parent_id).
      #    order_siblings(:position).

      records = children.map { |child| [child] + child.descendants }.reduce([], :+)

      ordered_tree_node.
          scope.
          extending(Relation::Preloaded, Relation::Arrangeable).
          records(records)
    end

    # Returns a set of itself and all of its nested children
    def self_and_descendants
      records = [self] + descendants

      ordered_tree_node.
          scope.
          extending(Relation::Preloaded, Relation::Arrangeable).
          records(records)
    end

    def is_descendant_of?(other)
      ancestors.include? other
    end

    def is_or_is_descendant_of?(other)
      self == other || is_descendant_of?(other)
    end

    def is_ancestor_of?(other)
      other.is_descendant_of? self
    end

    def is_or_is_ancestor_of?(other)
      other.is_or_is_descendant_of? self
    end

    # Return +true+ if this object is the first in the list.
    def first?
      self[position_column] <= 1
    end

    # Return +true+ if this object is the last in the list.
    def last?
      !right_sibling
    end

    def left_siblings
      siblings.where( arel[position_column].lt(self[position_column]) )
    end
    alias higher_items left_siblings

    # Returns a left (upper) sibling of the node
    def left_sibling
      higher_items.last
    end
    alias higher_item left_sibling

    def right_siblings
      siblings.where( arel[position_column].gt(self[position_column]) )
    end
    alias lower_items right_siblings

    # Returns a right (lower) sibling of the node
    def right_sibling
      right_siblings.first
    end
    alias lower_item right_sibling

    # Insert the item at the given position (defaults to the top position of 1).
    # +acts_as_list+ compatability
    def insert_at(position = 1)
      move_to_child_with_position(parent, position)
    end

    # Check if other model is in the same scope
    def same_scope?(other)
      scope_column_names.empty? || scope_column_names.all? do |attr|
        self[attr] == other[attr]
      end
    end

    private
    def compute_level #:nodoc:
      ancestors.count
    end

    # recursively load descendants
    def fetch_self_and_descendants #:nodoc:
      [self] + children.map { |child| [child, child.descendants] }.flatten
    end

    def arel #:nodoc:
      self.class.arel_table
    end

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
