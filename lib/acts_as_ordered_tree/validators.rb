module ActsAsOrderedTree
  module Validators #:nodoc:all:
    class CyclicReferenceValidator < ActiveModel::Validator
      def validate(record)
        record.errors.add(:parent, :invalid) if record.is_or_is_ancestor_of?(record.parent)
      end
    end

    class ScopeValidator < ActiveModel::Validator
      def validate(record)
        record.errors.add(:parent, :scope) unless record.ordered_tree_node.same_scope?(record.parent)
      end
    end
  end
end