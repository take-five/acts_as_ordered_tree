# coding: utf-8

module ActsAsOrderedTree
  # Position structure aggregates knowledge about node's position in the tree
  #
  # @api private
  class Position
    # This class represents node position change
    #
    # @api private
    class Transition
      # @return [ActsAsOrderedTree::Position]
      attr_reader :from

      # @return [ActsAsOrderedTree::Position]
      attr_reader :to

      # @param [ActsAsOrderedTree::Position] from
      # @param [ActsAsOrderedTree::Position] to
      def initialize(from, to)
        @from, @to = from, to
      end

      def changed?
        from != to
      end

      def reorder?
        changed? && from.parent_id == to.parent_id
      end

      def movement?
        changed? && from.parent_id != to.parent_id
      end

      def level_changed?
        from.depth != to.depth
      end

      def update_counters
        if movement?
          from.decrement_counter
          to.increment_counter
        end
      end
    end

    attr_reader   :node, :position
    attr_accessor :parent_id

    delegate :record, :to => :node
    delegate :parent, :to => :record

    # @param [ActsAsOrderedTree::Node] node
    # @param [Integer] parent_id
    # @param [Integer] position
    def initialize(node, parent_id, position)
      @node, @parent_id, self.position = node, parent_id, position
    end

    # attr_writer with coercion to [nil or Integer]
    def position=(value)
      @position = value.presence && value.to_i
    end

    def klass
      record.class
    end

    def parent
      return @parent if defined?(@parent)

      @parent = parent_id ? fetch_parent : nil
    end

    def parent?
      parent.present?
    end

    def root?
      parent.blank?
    end

    def depth
      @depth ||= parent ? parent.level + 1 : 0
    end

    # Locks current position. Technically, it means that pessimistic
    # lock will be obtained on parent node (or all root nodes if position is root)
    def lock!
      if parent
        parent.lock!
      else
        siblings.lock.reload
      end
    end

    # Returns true if node can have such position
    def valid?
      old_parent, old_position = node.parent_id, node.position
      node.parent_id, node.position = parent_id, position

      node.record.valid?
    ensure
      node.parent_id, node.position = old_parent, old_position
    end

    # predicate
    def position?
      position.present?
    end

    # Returns all nodes within given position
    def siblings
      node.scope.where(klass.ordered_tree.columns.parent => parent_id)
    end

    # Returns all nodes that are lower than current position
    def lower
      position? ?
          siblings.where(klass.arel_table[klass.ordered_tree.columns.position].gteq(position)) :
          siblings
    end

    def increment_counter
      update_counter(:increment_counter)
    end

    def decrement_counter
      update_counter(:decrement_counter)
    end

    # @param [ActsAsOrderedTree::Node::Position] other
    def ==(other)
      other.is_a?(self.class) &&
          other.node == node &&
          other.parent_id == parent_id &&
          other.position == position
    end

    private
    def fetch_parent
      parent_id == record[klass.ordered_tree.columns.parent] ?
          record.parent :
          node.scope.find(parent_id)
    end

    def update_counter(method)
      if (column = klass.ordered_tree.columns.counter_cache) && parent_id
        klass.send(method, column, parent_id)
      end
    end
  end # class Position
end