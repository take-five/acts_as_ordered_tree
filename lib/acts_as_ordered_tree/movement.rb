# coding: utf-8

module ActsAsOrderedTree
  # Movement class encapsulates nodes movements complexity
  #
  # @api private
  # @abstract
  class Movement
    require 'acts_as_ordered_tree/movement/movement_operation'
    require 'acts_as_ordered_tree/movement/reorder_operation'

    # Movement error is thrown when user tries to move node to impossible location
    Error = Class.new(ActiveRecord::ActiveRecordError)

    # Moved node
    attr_reader :node

    delegate :position_column,
             :depth_column,
             :parent_column,
             :ordered_tree_scope,
             :transaction,
             :to => :node

    def initialize(node)
      @node = node
    end

    # Moves the node
    def move
      node.tenacious_transaction do
        obtain_locks

        raise Error, 'Impossible movement' unless possible?

        return unless changed?

        perform_movement
      end
    end

    # Returns true if movement is possible
    def possible?
      # implement in successors
    end

    # Returns true if movement between branches should be performed
    def movement?
      node.id_was && parent_id_was != parent_id
    end

    # Returns true if node should change its position within siblings
    def reorder?
      node.id_was && parent_id_was == parent_id && position_was != position
    end

    # Returns true if updates should be performed
    def changed?
      movement? || reorder?
    end

    # Node position before movement
    def position_was
      node.send("#{position_column}_was")
    end

    # Node parent before movement
    def parent_id_was
      node.send("#{parent_column}_was")
    end

    # Node position after movement
    def position
      # implement in successors
    end

    # Node parent after movement
    def parent_id
      # implement in successors
    end

    # Node depth after movement
    def depth
      # implement in successors
    end

    # Shortcut
    def target_parent_id
      target[parent_column]
    end

    # Shortcut
    def target_position
      target[position_column]
    end

    protected
    def obtain_locks
      node.lock!
    end

    # Return node's current position
    def current_position
      node[position_column]
    end

    # Return true if node already positioned
    def positioned?
      node[position_column].present?
    end

    private
    def perform_movement
      # assign new values (for callbacks)
      node[position_column], node[parent_column] = position, parent_id

      case
        when movement?
          MovementOperation.new(self).execute

        when reorder?
          ReorderOperation.new(self).execute

        else
          # @todo i don't think this code is reachable ever (because of line 36, `return unless changed?`)
          node.reload
      end
    end
  end
  private_constant :Movement

  # @api private
  class MovementToRoot < Movement
    # moving node to root always possible
    def possible?
      true
    end

    def parent_id
      nil
    end

    def position
      if node.root? && positioned?
        current_position
      else
        highest_root_position + 1
      end
    end

    def depth
      0
    end

    private
    def obtain_locks
      super

      ordered_tree_scope.
        roots.
        lock(true).
        reload
    end

    def highest_root_position
      ordered_tree_scope.roots.maximum(position_column) || 0
    end
  end

  # @api private
  # @abstract
  class MovementToTarget < Movement
    def initialize(node, target)
      raise Error, "target node can't be nil" unless target

      super(node)
      @_target = target
    end

    def possible?
      node.same_scope?(target) && !node.is_or_is_ancestor_of?(target)
    end

    def target
      @target ||= node.class.lock(true).find(@_target)
    end
  end
  private_constant :MovementToTarget

  # @api private
  # @abstract
  class MovementToSiblingOfTarget < MovementToTarget
    def parent_id
      target_parent_id
    end

    def depth
      target.level
    end

    private
    def to_lower_sibling?
      position_was && parent_id == parent_id_was && target_position > position_was
    end
  end

  # @api private
  class MovementToLeftOfTarget < MovementToSiblingOfTarget
    def position
      if to_lower_sibling?
        target_position - 1
      else
        target_position
      end
    end
  end

  # @api private
  class MovementToRightOfTarget < MovementToSiblingOfTarget
    def position
      if to_lower_sibling?
        target_position
      else
        target_position + 1
      end
    end
  end

  # @api private
  class MovementToChildOfTarget < MovementToTarget
    def parent_id
      target.id
    end

    def depth
      target.level + 1
    end

    def position
      if already_child_of_target? && positioned?
        current_position
      else
        highest_child_position + 1
      end
    end

    private
    def already_child_of_target?
      node[parent_column] == parent_id
    end

    def highest_child_position
      target.children.maximum(position_column) || 0
    end
  end

  # @api private
  class MovementToChildWithIndex
    attr_reader :node, :target, :index

    def initialize(node, target, index)
      raise Movement::Error, "Movement index can't be empty" unless index

      @node, @target, @index = node, target, index
    end

    def move
      node.tenacious_transaction do
        movement.move
      end
    end

    private
    def siblings
      (target.try(:children) || node.ordered_tree_scope.roots).
          lock(true).
          reload.
          reject { |sibling| sibling == node }
    end

    def movement
      new_siblings = siblings

      if new_siblings.empty?
        target ?
            MovementToChildOfTarget.new(node, target) :
            MovementToRoot.new(node)
      elsif new_siblings.count <= index
        MovementToRightOfTarget.new(node, new_siblings.last)
      else
        index >= 0 ?
          MovementToLeftOfTarget.new(node, new_siblings[index]) :
          MovementToRightOfTarget.new(node, new_siblings[index])
      end
    end
  end
end