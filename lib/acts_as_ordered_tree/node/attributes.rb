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

      METHODS = ['', '?',  ?=, '_was', '_changed?', %w(reset_ !)].freeze

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
          METHODS.each do |prefix, suffix|
            prefix, suffix = suffix, prefix unless suffix
            method_name = "#{prefix}#{name}#{suffix}"

            define_method method_name do |*args|
              record.send "#{prefix}#{tree.columns[column_name_accessor]}#{suffix}", *args
            end
          end
        end
      end # module ClassMethods
    end # module Attributes
  end # class Node
end # module ActsAsOrderedTree