# coding: utf-8
require "acts_as_ordered_tree/tenacious_transaction"
require "acts_as_ordered_tree/relation/preloaded"

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
          where(:id => nodes.map(&:id)).
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
          where(:id => records.map(&:id)).
          records(records)
    end

    # Returns a set of itself and all of its nested children
    def self_and_descendants
      records = fetch_self_and_descendants

      ActsAsOrderedTree::Relation::Preloaded.new(self.class).
          where(:id => records.map(&:id)).
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
      move_to node, :left
    end
    alias move_to_above_of move_to_left_of

    # Move the node to the left of another node
    def move_to_right_of(node)
      move_to node, :right
    end
    alias move_to_bottom_of move_to_right_of

    # Move the node to the child of another node
    def move_to_child_of(node)
      move_to node, :child
    end

    # Move the node to the child of another node with specify index
    def move_to_child_with_index(node, index)
      raise ActiveRecord::ActiveRecordError, "index can't be nil" unless index

      tenacious_transaction do
        new_siblings = (node.try(:children) || self.class.roots).
            reload.
            lock(true).
            reject { |root_node| root_node == self }

        if new_siblings.empty?
          node ? move_to_child_of(node) : move_to_root
        elsif new_siblings.count <= index
          move_to_right_of(new_siblings.last)
        elsif
          index >= 0 ? move_to_left_of(new_siblings[index]) : move_to_right_of(new_siblings[index])
        end
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
          position -= 1 if target[parent_column] == send("#{parent_column}_was") && target[position_column] > position_was # right
          depth = target.level
        when :right then
          parent_id = target[parent_column]
          position = target[position_column]
          position += 1 if target[parent_column] != send("#{parent_column}_was") || target[position_column] < position_was # left
          depth = target.level
        when :child then
          parent_id = target.id
          position = if self[parent_column] == parent_id && self[position_column]
            # already child of target node
            self[position_column]
          else
            # lock should be obtained on target
            target.children.maximum(position_column).try(:succ) || 1
          end
          depth = target.level + 1
        else raise ActiveRecord::ActiveRecordError, "Position should be :child, :left, :right or :root ('#{pos}' received)."
      end
      return parent_id, position, depth
    end

    # This method do real node movements
    def move_to(target, pos) #:nodoc:
      tenacious_transaction do
        if target.is_a? self.class.base_class
          # lock obtained here
          target.send(:reload_node)
        elsif pos != :root && target
          # load object if node is not an object
          target = self.class.find(target, :lock => true)
        elsif pos == :root
          # Obtain lock on all root nodes
          ordered_tree_scope.
              roots.
              lock(true).
              reload
        end

        unless pos == :root || target && move_possible?(target)
          raise ActiveRecord::ActiveRecordError, "Impossible move"
        end

        position_was = send "#{position_column}_was".intern
        parent_id_was = send "#{parent_column}_was".intern
        parent_id, position, depth = compute_ordered_tree_columns(target, pos)
        self[parent_column], self[position_column] = parent_id, position

        # nothing changed - quit
        return if parent_id == parent_id_was && position == position_was

        move_kind = case
          when id_was && parent_id != parent_id_was then :move
          when id_was && position  != position_was  then :reorder
          else nil
        end

        update = proc do
          if move_kind == :move
            move!(id, parent_id_was, parent_id, position_was, position, depth)
          else
            reorder!(parent_id, position_was, position)
          end

          reload_node
        end

        if move_kind
          run_callbacks move_kind, &update
        else
          update.call
        end
      end
    end

    def decrement_lower_positions(parent_id, position) #:nodoc:
      conditions = arel[parent_column].eq(parent_id).and(arel[position_column].gt(position))

      ordered_tree_scope.where(conditions).update_all("#{position_column} = #{position_column} - 1")
    end

    # Internal
    def move!(id, parent_id_was, parent_id, position_was, position, depth) #:nodoc:
      pk = self.class.primary_key

      assignments = [
          "#{parent_column} = CASE " +
              "WHEN #{pk} = :id " +
              "THEN :parent_id " +
              "ELSE #{parent_column} " +
          "END",
          "#{position_column} = CASE " +
              # set new position
              "WHEN #{pk} = :id " +
              "THEN :position " +
              # decrement lower positions within old parent
              "WHEN #{parent_column} #{parent_id_was.nil? ? " IS NULL" : " = :parent_id_was"} AND #{position_column} > :position_was " +
              "THEN #{position_column} - 1 " +
              # increment lower positions within new parent
              "WHEN #{parent_column} #{parent_id.nil? ? "IS NULL" : " = :parent_id"} AND #{position_column} >= :position " +
              "THEN #{position_column} + 1 " +
              "ELSE #{position_column} " +
          "END",
          ("#{depth_column} = CASE " +
              "WHEN #{pk} = :id " +
              "THEN :depth " +
              "ELSE #{depth_column} " +
          "END" if depth_column)
      ].compact.join(', ')

      conditions = arel[pk].eq(id).or(
        arel[parent_column].eq(parent_id_was)
      ).or(
        arel[parent_column].eq(parent_id)
      )

      binds = {:id => id,
               :parent_id_was => parent_id_was,
               :parent_id => parent_id,
               :position_was => position_was,
               :position => position,
               :depth => depth}

      update_changed_attributes! conditions, assignments, binds
    end

    # Internal
    def reorder!(parent_id, position_was, position)
      assignments = if position_was
        <<-SQL
        #{position_column} = CASE
            WHEN #{position_column} = :position_was
            THEN :position
            WHEN #{position_column} <= :position AND #{position_column} > :position_was AND :position > :position_was
            THEN #{position_column} - 1
            WHEN #{position_column} >= :position AND #{position_column} < :position_was AND :position < :position_was
            THEN #{position_column} + 1
            ELSE #{position_column}
        END
        SQL
      else
        <<-SQL
        #{position_column} = CASE
            WHEN #{position_column} > :position
            THEN #{position_column} + 1
            WHEN #{position_column} IS NULL
            THEN :position
            ELSE #{position_column}
        END
        SQL
      end

      conditions = arel[parent_column].eq(parent_id)
      binds = {:position_was => position_was, :position => position}

      update_changed_attributes! conditions, assignments, binds
    end

    def update_changed_attributes!(scope_conditions, assignments, binds)
      # update externally changed attributes
      external_changed_attrs = changed - [parent_column, position_column, depth_column]
      unless external_changed_attrs.empty?
        external_assignments = external_changed_attrs.inject({}) do |hash, attribute|
          hash[attribute] = self[attribute]
          hash
        end
        ordered_tree_scope.update_all(external_assignments, self.class.primary_key => id)
      end

      # update internal attributes
      ordered_tree_scope.where(scope_conditions).update_all([assignments, binds])
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
      depth_was = self[depth_column]

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

    def ordered_tree_scope #:nodoc:
      if scope_column_names.empty?
        self.class.base_class.scoped
      else
        self.class.base_class.where Hash[scope_column_names.map { |column| [column, self[column]] }]
      end
    end
  end # module InstanceMethods
end # module ActsAsOrderedTree
