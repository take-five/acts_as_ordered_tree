module ActsAsOrderedTree
  module InstanceMethods
    extend ActiveSupport::Concern

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
      fake_scope(self.class.where(:id => nodes.map(&:id)), nodes)
    end

    # Returns the array of all parents starting from root
    def ancestors
      records = self_and_ancestors - [self]

      scope = self_and_ancestors.where(arel[:id].not_eq(id))
      fake_scope scope, records
    end

    # Returns the array of all children of the parent, including self
    def self_and_siblings
      self.class.preorder.where(parent_column => self[parent_column])
    end

    # Returns the array of all children of the parent, except self
    def siblings
      self_and_siblings.where(arel[:id].not_eq(id))
    end

    def level
      # cached result becomes invalid when parent is changed
      if new_record? ||
          changed_attributes.include?(parent_column.to_s) ||
          self[depth_column].blank?
        self[depth_column] = compute_level
      else
        self[depth_column]
      end
    end

    # Returns a set of all of its children and nested children.
    # A little bit tricky. use RDBMS with recursive queries support (PostgreSQL)
    def descendants
      @descendants_iterator ||= Iterator.new do |yielder|
        children.each do |child|
          yielder << child

          next if self.class.send(:children_counter_cache?) && child.leaf?

          child.descendants.each do |grandchild|
            yielder << grandchild
          end
        end
      end.tap do |iter|
        #iter.class_eval " attr_accessor :parent_ids "
        class << iter
          attr_accessor :parent_ids
        end

        iter.parent_ids = iter.map { |record| record[parent_column] }.uniq
      end

      fake_scope self.class.where(parent_column => @descendants_iterator.parent_ids), @descendants_iterator
    end

    # Returns a set of itself and all of its nested children
    def self_and_descendants
      records = descendants.to_a

      fake_scope self.class.where(arel[parent_column].in(records.parent_ids).or(arel[:id].eq(id))), [self] + records
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

    def left_sibling
      siblings.
          where( arel[position_column].lt(self[position_column]) ).
          reorder( arel[position_column].desc ).
          first
    end
    alias higher_item left_sibling

    def right_sibling
      siblings.
          where( arel[position_column].gt(self[position_column]) ).
          first
    end
    alias lower_item right_sibling

    # Shorthand method for finding the left sibling and moving to the left of it.
    def move_left
      move_to_left_of left_sibling
    end
    alias move_higher move_left

    # Shorthand method for finding the right sibling and moving to the right of it.
    def move_right
      move_to_right_of right_sibling
    end
    alias move_lower move_right

    # Move the node to the left of another node
    def move_to_left_of(node)
      move_to node, :left
    end

    # Move the node to the left of another node
    def move_to_right_of(node)
      move_to node, :right
    end

    # Move the node to the child of another node
    def move_to_child_of(node)
      move_to node, :child
    end

    # Move the node to the child of another node with specify index (you can pass id only)
    def move_to_child_with_index(node, index)
      if node.children.empty?
        move_to_child_of(node)
      elsif node.children.count == index
        move_to_right_of(node.children.last)
      else
        move_to_left_of(node.children[index])
      end
    end

    # Move the node to root nodes
    def move_to_root
      move_to nil, :root
    end

    def move_possible?(target)
      !is_or_is_ancestor_of?(target)
    end

    private
    def compute_level
      ancestors.count
    end

    def fake_scope(scope, records) #:nodoc:
      scope.instance_variable_set :@loaded, true
      scope.instance_variable_set :@records, records

      # do preload
      preload = scope.preload_values
      preload +=  scope.includes_values unless scope.eager_loading?
      preload.each do |associations|
        ActiveRecord::Associations::Preloader.new(records, associations).run
      end

      # mark records as readonly
      records.each &:readonly! if scope.readonly_value

      scope
    end

    def arel #:nodoc:
      self.class.arel_table
    end
  end # module InstanceMethods
end # module ActsAsOrderedTree