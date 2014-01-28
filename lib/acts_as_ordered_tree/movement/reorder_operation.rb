# coding: utf-8

require 'acts_as_ordered_tree/movement/operation'

module ActsAsOrderedTree
  # @api private
  class Movement::ReorderOperation < Movement::Operation
    def execute
      run_callbacks :reorder do
        ordered_tree_scope.
          where(parent_column => parent_id).
          update_all([assignment, :position => position, :position_was => position_was])
      end
    end

    private
    def assignment
      if position_was
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
    end
  end
end