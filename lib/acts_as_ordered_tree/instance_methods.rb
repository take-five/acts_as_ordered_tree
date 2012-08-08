# coding: utf-8
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
      ActsAsOrderedTree::FakeScope.new(self.class, nodes, :where => {:id => nodes.map(&:id)})
    end

    # Returns the array of all parents starting from root
    def ancestors
      records = self_and_ancestors - [self]

      scope = self_and_ancestors.where(arel[:id].not_eq(id))
      ActsAsOrderedTree::FakeScope.new(scope, records)
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

      ActsAsOrderedTree::FakeScope.new self.class, records, :where => {:id => records.map(&:id)}
    end

    # Returns a set of itself and all of its nested children
    def self_and_descendants
      records = fetch_self_and_descendants

      ActsAsOrderedTree::FakeScope.new self.class, records, :where => {:id => records.map(&:id)}
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

    # Move the node to the child of another node with specify index
    def move_to_child_with_index(node, index)
      raise ActiveRecord::ActiveRecordError, "index cant be nil" unless index
      new_siblings = node.try(:children) || self.class.roots.delete_if { |root_node| root_node == self }

      if new_siblings.empty?
        node ? move_to_child_of(node) : move_to_root
      elsif new_siblings.count <= index
        move_to_right_of(new_siblings.last)
      elsif
        index >= 0 ? move_to_left_of(new_siblings[index]) : move_to_right_of(new_siblings[index])
      end
    end

    # Move the node to root nodes
    def move_to_root
      move_to nil, :root
    end

    # Returns +true+ it is possible to move node to left/right/child of +target+
    def move_possible?(target)
      same_scope?(target) && !is_or_is_ancestor_of?(target)
    end

    # Check if other model is in the same scope
    def same_scope?(other)
      scope_column_names.empty? || scope_column_names.all? do |attr|
        self[attr] == other[attr]
      end
    end

    private
    # reloads relevant ordered_tree columns
    def reload_node #:nodoc:
      reload(
        :select => [parent_column,
                    position_column,
                    depth_column,
                    children_counter_cache_column].compact,
        :lock => true
      )
    end

    def compute_level #:nodoc:
      ancestors.count
    end

    def compute_ordered_tree_columns(target, pos) #:nodoc:
      case pos
        when :root  then
          parent_id = nil
          position = if root? && self[position_column]
            # already root node
            self[position_column]
          else
            ordered_tree_scope.roots.maximum(position_column).try(:succ) || 1
          end
          depth = 0
        when :left  then
          parent_id = target[parent_column]
          position = target[position_column]
          position -= 1 if target[parent_column] == self[parent_column] && target[position_column] > position_was # right
          depth = target.level
        when :right then
          parent_id = target[parent_column]
          position = target[position_column]
          position += 1 if target[parent_column] != self[parent_column] || target[position_column] < position_was # left
          depth = target.level
        when :child then
          parent_id = target.id
          position = if self[parent_column] == parent_id && self[position_column]
            # already children of target node
            self[position_column]
          else
            target.children.maximum(position_column).try(:succ) || 1
          end
          depth = target.level + 1
        else raise ActiveRecord::ActiveRecordError, "Position should be :child, :left, :right or :root ('#{pos}' received)."
      end
      return parent_id, position, depth
    end

    # This method do real node movements
    def move_to(target, pos) #:nodoc:
      if target.is_a? self.class.base_class
        target.reload
      elsif pos != :root && target
        # load object if node is not an object
        target = self.class.find(target)
      end

      unless pos == :root || target && move_possible?(target)
        raise ActiveRecord::ActiveRecordError, "Impossible move"
      end

      position_was = send "#{position_column}_was".intern
      parent_id_was = send "#{parent_column}_was".intern
      parent_id, position, depth = compute_ordered_tree_columns(target, pos)

      # nothing changed - quit
      return if parent_id == parent_id_was && position == position_was

      update = proc do
        decrement_lower_positions parent_id_was, position_was if position_was
        increment_lower_positions parent_id, position

        columns = {parent_column => parent_id, position_column => position}
        columns[depth_column] = depth if depth_column

        ordered_tree_scope.update_all(columns, :id => id)
        reload_node
      end

      if id_was && parent_id != parent_id_was
        run_callbacks :move, &update
      else
        update.call
      end
    end

    def decrement_lower_positions(parent_id, position) #:nodoc:
      conditions = arel[parent_column].eq(parent_id).and(arel[position_column].gt(position))

      ordered_tree_scope.update_all "#{position_column} = #{position_column} - 1", conditions
    end

    def increment_lower_positions(parent_id, position) #:nodoc:
      conditions = arel[parent_column].eq(parent_id).and(arel[position_column].gteq(position))

      ordered_tree_scope.update_all "#{position_column} = #{position_column} + 1", conditions
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

    def destroy_descendants
      descendants.delete_all
      # flush memoization
      @self_and_descendants = nil
    end

    def arel #:nodoc:
      self.class.arel_table
    end

    def ordered_tree_scope
      if scope_column_names.empty?
        self.class.scoped
      else
        self.class.where Hash[scope_column_names.map { |column| [column, self[column]] }]
      end
    end
  end # module InstanceMethods
end # module ActsAsOrderedTree