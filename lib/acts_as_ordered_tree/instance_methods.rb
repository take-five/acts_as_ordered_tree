# coding: utf-8
require 'acts_as_ordered_tree/tenacious_transaction'
require 'acts_as_ordered_tree/relation/preloaded'
require 'acts_as_ordered_tree/movement'
require 'acts_as_ordered_tree/arrangeable'

module ActsAsOrderedTree
  module InstanceMethods
    include ActsAsOrderedTree::TenaciousTransaction

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

      # 3. create fake scope
      ActsAsOrderedTree::Relation::Preloaded.new(self.class).
          where(:id => nodes.map(&:id).compact).
          extending(Arrangeable).
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
      ordered_tree_scope.where(parent_column => self[parent_column])
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
      records = fetch_self_and_descendants - [self]

      ActsAsOrderedTree::Relation::Preloaded.new(self.class).
          where(:id => records.map(&:id).compact).
          extending(Arrangeable).
          records(records)
    end

    # Returns a set of itself and all of its nested children
    def self_and_descendants
      records = fetch_self_and_descendants

      ActsAsOrderedTree::Relation::Preloaded.new(self.class).
          where(:id => records.map(&:id)).
          extending(Arrangeable).
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

    # Returns a left (upper) sibling of the node
    def left_sibling
      siblings.
          where( arel[position_column].lt(self[position_column]) ).
          reorder( arel[position_column].desc ).
          first
    end
    alias higher_item left_sibling

    # Returns a right (lower) sibling of the node
    def right_sibling
      siblings.
          where( arel[position_column].gt(self[position_column]) ).
          reorder( arel[position_column].asc ).
          first
    end
    alias lower_item right_sibling

    # Insert the item at the given position (defaults to the top position of 1).
    # +acts_as_list+ compatability
    def insert_at(position = 1)
      move_to_child_with_index(parent, position - 1)
    end

    # Shorthand method for finding the left sibling and moving to the left of it.
    def move_left
      tenacious_transaction do
        move_to_left_of left_sibling.try(:lock!)
      end
    end
    alias move_higher move_left

    # Shorthand method for finding the right sibling and moving to the right of it.
    def move_right
      tenacious_transaction do
        move_to_right_of right_sibling.try(:lock!)
      end
    end
    alias move_lower move_right

    # Move the node to the left of another node
    def move_to_left_of(node)
      MovementToLeftOfTarget.new(self, node).move
    end
    alias move_to_above_of move_to_left_of

    # Move the node to the left of another node
    def move_to_right_of(node)
      MovementToRightOfTarget.new(self, node).move
    end
    alias move_to_bottom_of move_to_right_of

    # Move the node to the child of another node
    def move_to_child_of(node)
      MovementToChildOfTarget.new(self, node).move
    end

    # Move the node to the child of another node with specify index
    def move_to_child_with_index(node, index)
      MovementToChildWithIndex.new(self, node, index).move
    end

    # Move the node to root nodes
    def move_to_root
      MovementToRoot.new(self).move
    end

    # Check if other model is in the same scope
    def same_scope?(other)
      scope_column_names.empty? || scope_column_names.all? do |attr|
        self[attr] == other[attr]
      end
    end

    def ordered_tree_scope #:nodoc:
      if scope_column_names.empty?
        self.class.base_class
      else
        self.class.base_class.where Hash[scope_column_names.map { |column| [column, self[column]] }]
      end
    end

    private
    def compute_level #:nodoc:
      ancestors.count
    end

    def decrement_lower_positions(parent_id, position) #:nodoc:
      conditions = arel[parent_column].eq(parent_id).and(arel[position_column].gt(position))

      ordered_tree_scope.where(conditions).update_all("#{position_column} = #{position_column} - 1")
    end

    # recursively load descendants
    def fetch_self_and_descendants #:nodoc:
      @self_and_descendants ||= [self] + children.map { |child| [child, child.descendants] }.flatten
    end

    def set_depth! #:nodoc:
      self[depth_column] = compute_level
    end

    def set_scope! #:nodoc:
      scope_column_names.each do |column|
        self[column] = parent[column]
      end
    end

    def flush_descendants #:nodoc:
      @self_and_descendants = nil
    end

    def update_descendants_depth #:nodoc:
      depth_was = send("#{depth_column}_was")

      yield

      diff = self[depth_column] - depth_was
      if diff != 0
        sign = diff > 0 ? "+" : "-"
        # update categories set depth = depth - 1 where id in (...)
        descendants.update_all(["#{depth_column} = #{depth_column} #{sign} ?", diff.abs]) if descendants.count > 0
      end
    end

    # Used in built-in around_move routine
    def update_counter_cache #:nodoc:
      parent_id_was = send "#{parent_column}_was"

      yield

      parent_id_new = self[parent_column]
      unless parent_id_new == parent_id_was
        self.class.increment_counter(children_counter_cache_column, parent_id_new) if parent_id_new
        self.class.decrement_counter(children_counter_cache_column, parent_id_was) if parent_id_was
      end
    end

    def arel #:nodoc:
      self.class.arel_table
    end
  end # module InstanceMethods
end # module ActsAsOrderedTree
