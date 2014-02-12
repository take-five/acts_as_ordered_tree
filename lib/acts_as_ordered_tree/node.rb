# coding: utf-8

require 'active_support/dependencies/autoload'

require 'acts_as_ordered_tree/position'
require 'acts_as_ordered_tree/transaction/create'
require 'acts_as_ordered_tree/transaction/move'
require 'acts_as_ordered_tree/transaction/reorder'
require 'acts_as_ordered_tree/transaction/destroy'

module ActsAsOrderedTree
  # ActsAsOrderedTree::Node takes care of tree integrity when record is saved
  # via usual ActiveRecord mechanism
  class Node
    extend ActiveSupport::Autoload

    autoload :Attributes
    autoload :Movements
    autoload :Reloading

    include Attributes
    include Movements
    include Reloading

    # @attr_reader [ActiveRecord::Base] original AR record, created, updated or destroyed
    attr_reader :record

    delegate :id, :parent, :children, :==, :to => :record

    def initialize(record)
      @record = record
    end

    # Returns scope to which record should be applied
    def scope
      if record.scope_column_names.empty?
        record.class.base_class.where(nil)
      else
        record.class.base_class.where Hash[record.scope_column_names.map { |column| [column, record[column]] }]
      end
    end

    # ? should it really be here?
    def siblings
      scope.where(record.class.parent_column => parent_id)
    end
  end # class Node
end # module ActsAsOrderedTree