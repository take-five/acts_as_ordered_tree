# coding: utf-8

module ActsAsOrderedTree
  # @api private
  class Movement::Operation
    delegate :parent_column,
             :position_column,
             :depth_column,
             :parent_id,
             :position,
             :depth,
             :parent_id_was,
             :position_was,
             :ordered_tree_scope,
             :to => :@movement

    def initialize(movement)
      @movement = movement
    end

    def run_callbacks(kind)
      @movement.node.run_callbacks(kind) do
        yield

        @movement.node.reload
      end
    end
  end
end