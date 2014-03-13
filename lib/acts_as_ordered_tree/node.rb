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
    #
    # @todo apply with_default_scope here
    def scope
      if tree.columns.scope?
        tree.base_class.where Hash[tree.columns.scope.map { |column| [column, record[column]] }]
      else
        tree.base_class.where(nil)
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
      case
        when depth_column_could_be_used? then depth
        when parent_association_loaded? then parent.level + 1
        # @todo move it adapters
        else ancestors.size
      end
    end

    private
    # @return [Arel::Table]
    def table
      record.class.arel_table
    end

    def depth_column_could_be_used?
      tree.columns.depth? && record.persisted? && !parent_id_changed? && depth?
    end

    def parent_association_loaded?
      record.association(:parent).loaded?
    end
  end # class Node
end # module ActsAsOrderedTree