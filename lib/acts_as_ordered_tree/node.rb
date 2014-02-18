# coding: utf-8

require 'acts_as_ordered_tree/node/attributes'
require 'acts_as_ordered_tree/node/movements'
require 'acts_as_ordered_tree/node/predicates'
require 'acts_as_ordered_tree/node/reloading'
require 'acts_as_ordered_tree/node/siblings'
require 'acts_as_ordered_tree/node/traversals'

module ActsAsOrderedTree
  # ActsAsOrderedTree::Node takes care of tree integrity when record is saved
  # via usual ActiveRecord mechanism
  class Node
    include Attributes
    include Movements
    include Predicates
    include Reloading
    include Siblings
    include Traversals

    # @attr_reader [ActiveRecord::Base] original AR record, created, updated or destroyed
    attr_reader :record

    delegate :id, :parent, :children, :==, :to => :record

    def initialize(record)
      @record = record
    end

    # Returns scope to which record should be applied
    def scope
      base_class = if record.class.finder_needs_type_condition?
                     record.class.base_class
                   else
                     record.class
                   end

      if tree.columns.scope?
        base_class.where Hash[tree.columns.scope.map { |column| [column, record[column]] }]
      else
        base_class.where(nil)
      end
    end

    # Convert node to AR::Relation
    #
    # @return [ActiveRecord::Relation]
    def to_relation
      scope.where(tree.columns.id => id)
    end

    # @return [ActsAsOrderedTree::Tree]
    def tree
      record.class.ordered_tree
    end

    # Returns node level value (0 for root)
    #
    # @return [Fixnum]
    def level
      if tree.columns.depth? && record.persisted? && !parent_id_changed? && depth?
        depth
      else
        # @todo move it adapters
        # @todo check if parent loaded and return its level
        ancestors.size
      end
    end

    private
    # @return [Arel::Table]
    def table
      record.class.arel_table
    end
  end # class Node
end # module ActsAsOrderedTree