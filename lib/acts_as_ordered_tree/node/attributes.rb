# coding: utf-8

require 'active_support/concern'

module ActsAsOrderedTree
  class Node
    # This module when included creates accessor to record's attributes that related to tree structure
    #
    # @example
    #   class Node
    #     include Attributes
    #   end
    #
    #   node = Node.new(record)
    #   node.parent_id # => record.parent_id
    #   node.position # => record.position
    #   node.position_was # => record.position_was
    #   # etc.
    module Attributes
      extend ActiveSupport::Concern

      included do
        dynamic_attribute_accessor :position
        dynamic_attribute_accessor :parent_id, :parent
        dynamic_attribute_accessor :depth
        dynamic_attribute_accessor :counter_cache
      end

      module ClassMethods
        # Generates methods based on configurable record attributes
        #
        # @api private
        def dynamic_attribute_accessor(name, column_name_accessor = name)
          class_eval <<-ERUBY, __FILE__, __LINE__ + 1
            def #{name}
              record.send(record.ordered_tree.columns.#{column_name_accessor})
            end

            def #{name}?
              record.send("#\{record.ordered_tree.columns.#{column_name_accessor}}?")
            end

            def #{name}=(value)
              record.send("#\{record.ordered_tree.columns.#{column_name_accessor}}=", value)
            end

            def #{name}_was
              record.send("#\{record.ordered_tree.columns.#{column_name_accessor}}_was")
            end

            def #{name}_changed?
              record.send("#\{record.ordered_tree.columns.#{column_name_accessor}}_changed?")
            end
          ERUBY
        end
      end
    end
  end
end