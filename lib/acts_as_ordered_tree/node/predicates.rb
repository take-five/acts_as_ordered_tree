# coding: utf-8

module ActsAsOrderedTree
  module Node::Predicates
    # Returns true if this is a root node.
    def root?
      !parent_id?
    end

    # Returns true if this is the end of a branch.
    def leaf?
      # children.size won't execute SQL-queries if counter_cache is set, so it's ok
      record.persisted? && children.size == 0
    end

    # Returns true if node contains any children.
    def branch?
      !leaf?
    end

    # Returns true is node is not a root node.
    def child?
      !root?
    end

    # Returns true if current node is descendant of +other+ node.
    #
    # @param [ActiveRecord::Base] other
    def is_descendant_of?(other)
      same_scope?(other) && ancestors.include?(other)
    end

    # Returns true if current node is equal to +other+ node or is descendant of +other+ node.
    #
    # @param [ActiveRecord::Base] other
    def is_or_is_descendant_of?(other)
      record == other || is_descendant_of?(other)
    end

    # Returns true if current node is ancestor of +other+ node.
    #
    # @param [ActiveRecord::Base] other
    def is_ancestor_of?(other)
      same_scope?(other) && other.is_descendant_of?(record)
    end

    # Returns true if current node is equal to +other+ node or is ancestor of +other+ node.
    #
    # @param [ActiveRecord::Base] other
    def is_or_is_ancestor_of?(other)
      same_scope?(other) && other.is_or_is_descendant_of?(record)
    end

    # Return +true+ if this object is the first in the list.
    def first?
      position <= 1
    end

    # Return +true+ if this object is the last in the list.
    def last?
      !right_sibling
    end

    # Check if other node is in the same scope
    #
    # @api private
    def same_scope?(other)
      other.class == record.class && tree.columns.scope.all? do |attr|
        record[attr] == other[attr]
      end
    end
  end
end