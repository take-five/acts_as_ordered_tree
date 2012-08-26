module ActsAsOrderedTree
  module Relation
    class Base < ActiveRecord::Relation
      # Create from existing +relation+ or from +class+ and +table+
      def initialize(class_or_relation, table = nil)
        relation = class_or_relation

        if class_or_relation.is_a?(Class)
          relation = class_or_relation.scoped
          table ||= class_or_relation.arel_table

          super(class_or_relation, table)
        else
          super(class_or_relation.klass, class_or_relation.table)
        end

        # copy instance variables from real relation
        relation.instance_variables.each do |ivar|
          instance_variable_set(ivar, relation.instance_variable_get(ivar))
        end
      end
    end
  end
end