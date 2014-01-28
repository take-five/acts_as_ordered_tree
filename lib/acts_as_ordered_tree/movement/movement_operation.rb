# coding: utf-8

require 'acts_as_ordered_tree/movement/operation'

module ActsAsOrderedTree
  # @api private
  class Movement::MovementOperation < Movement::Operation
    def execute
      run_callbacks :move do
        ordered_tree_scope.where(conditions).update_all([assignments.compact.join(', '), binds])
      end
    end

    private
    def conditions
      attr(primary_key_column).eq(primary_key).or(
          attr(parent_column).eq(parent_id_was)
      ).or(
          attr(parent_column).eq(parent_id)
      )
    end

    # @todo still too complex
    def assignments
      [
          "#{parent_column} = CASE " +
              "WHEN #{primary_key_column} = :id " +
              "THEN :parent_id " +
              "ELSE #{parent_column} " +
              "END",
          "#{position_column} = CASE " +
              # set new position
              "WHEN #{primary_key_column} = :id " +
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
              "WHEN #{primary_key_column} = :id " +
              "THEN :depth " +
              "ELSE #{depth_column} " +
              "END" if depth_column)
      ]
    end

    def binds
      {:id => primary_key,
       :parent_id_was => parent_id_was,
       :parent_id => parent_id,
       :position_was => position_was,
       :position => position,
       :depth => depth}
    end

    def primary_key_column
      @movement.node.class.primary_key
    end

    def primary_key
      @movement.node.id
    end

    def attr(name)
      @movement.node.class.arel_table[name]
    end
  end
end