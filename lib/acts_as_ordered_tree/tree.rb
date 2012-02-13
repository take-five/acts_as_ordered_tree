require "active_support/concern"

module ActsAsOrderedTree
  module Tree
    extend ActiveSupport::Concern

    included do
      # remove +acts_as_tree+ version of +roots+ method
      class << self
        remove_method :roots

        # Retrieve first root node
        #
        # Replacement for native +ActsAsTree.root+ method
        def root
          roots.first
        end
      end

      scope :roots, where(parent_column => nil).order(quoted_position_column)

      validate :validate_incest

      define_model_callbacks :move
      around_update :__around_move, :if => :parent_changed?
    end

    # == Instance methods

    # returns a Enumerator of ancestors, starting from parent until root
    def ancestors
      Iterator.new do |yielder|
        node = self
        yielder << node while node = node.parent
      end
    end

    # returns a Enumerator of ancestors, including self
    def self_and_ancestors
      Iterator.new do |y|
        y << self
        ancestors.each { |a| y << a }
      end
    end

    # returns a Enumerator of node's descendants, traversing depth first
    #
    # == Example
    # The tree:
    #   # * root
    #   #   * child_1
    #   #     * grandchild_1_1
    #   #     * grandchild_1_2
    #   #   * child_2
    #   #     * grandchild_2_1
    #
    #   root.descendants # => [root,
    #                    #     child_1, grandchild_1_1, grandchild_1_2,
    #                    #     child_2, grandchild_2_1]
    def descendants
      Iterator.new do |yielder|
        children.each do |child|
          yielder << child

          child.descendants.each do |grandchild|
            yielder << grandchild
          end
        end
      end
    end # def descendants

    def self_and_descendants
      Iterator.new do |y|
        y << self
        descendants.each { |x| y << x }
      end
    end

    # Returns depth of current node
    def depth
      ancestors.count
    end
    alias level depth

    # Return +true+ if +self+ is root node
    def root?
      self[parent_column].nil?
    end

    # Return +true+ if +self+ is leaf node
    def leaf?
      children.empty?
    end

    # Returns true if record has changes in +parent_id+
    def parent_changed?
      changes.has_key?(parent_column.to_s)
    end

    # Move node to other parent, make it last child of new parent
    def move_to_child_of(another_parent)
      transaction do
        self.parent = another_parent

        p_changed = parent_changed?
        save if p_changed

        skip_reorder_callbacks(p_changed) { move_to_bottom }

        parent.children.reload
      end
    end

    # Move node to position of +another_node+, shift down lower items
    def move_to_above_of(another_node)
      p_changed = parent != another_node.parent

      transaction do
        move_to_child_of(another_node.parent)
        
        skip_reorder_callbacks(p_changed) do
          insert_at(another_node[position_column])
        end

        another_node.parent.children.reload if another_node.parent.present?
        another_node.reload
      end
    end

    # Move node to the next of +another_node+, shift down lower items
    def move_to_bottom_of(another_node)
      transaction do
        self.parent = another_node.parent
        self[position_column] = another_node[position_column] + 1

        save
        
        another_node.parent.children.reload if another_node.parent.present?
      end
    end

    protected
    def validate_incest #:nodoc:
      errors.add(:parent, :linked_to_self) if parent == self
      errors.add(:parent, :linked_to_descendant) if descendants.include?(parent)
    end

    def __around_move #:nodoc:
      run_callbacks(:move) { yield }
    end
  end # module Tree
end # module ActsAsOrderedTree