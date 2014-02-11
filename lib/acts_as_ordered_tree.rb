require 'active_record'
require 'acts_as_ordered_tree/version'
require 'acts_as_ordered_tree/class_methods'
require 'acts_as_ordered_tree/instance_methods'
require 'acts_as_ordered_tree/validators'

module ActsAsOrderedTree
  PROTECTED_ATTRIBUTES_SUPPORTED = ActiveRecord::VERSION::MAJOR < 4 ||
    defined?(ProtectedAttributes)

  # can we use has_many :children, :order => :position
  PLAIN_ORDER_OPTION_SUPPORTED = ActiveRecord::VERSION::MAJOR < 4

  # == Usage
  #   class Category < ActiveRecord::Base
  #     acts_as_ordered_tree :parent_column => :parent_id,
  #                          :position_column => :position,
  #                          :depth_column => :depth,
  #                          :counter_cache => :children_count
  #   end
  def acts_as_ordered_tree(options = {})
    options = {
      :parent_column   => :parent_id,
      :position_column => :position,
      :depth_column    => :depth
    }.merge(options)

    class_attribute :acts_as_ordered_tree_options, :instance_writer => false
    self.acts_as_ordered_tree_options = options

    acts_as_ordered_tree_options[:depth_column] = nil unless
        columns_hash.include?(acts_as_ordered_tree_options[:depth_column].to_s)

    extend  Columns
    include Columns

    has_many_children_options = {
      :class_name    => "::#{base_class.name}",
      :foreign_key   => options[:parent_column],
      :inverse_of    => (:parent unless options[:polymorphic]),
      :dependent     => :destroy
    }

    [:before_add, :after_add, :before_remove, :after_remove].each do |key|
      has_many_children_options[key] = options[key] if options.key?(key)
    end

    if PLAIN_ORDER_OPTION_SUPPORTED
      has_many_children_options[:order] = options[:position_column]

      if scope_column_names.any?
        has_many_children_options[:conditions] = proc do
          [scope_column_names.map { |c| "#{c} = ?" }.join(' AND '),
           scope_column_names.map { |c| self[c] }]
        end
      end

      has_many :children, has_many_children_options
    else
      scope = ->(parent) {
        relation = order(options[:position_column])

        if scope_column_names.any?
          relation = relation.where(
            Hash[scope_column_names.map { |c| [c, parent[c]]}]
          )
        end

        relation
      }

      has_many :children, scope, has_many_children_options
    end

    # create parent association
    #
    # we cannot use native :counter_cache callbacks because they suck! :(
    # they act like this:
    #   node.parent = new_parent # and here counters are updated, outside of transaction!
    belongs_to :parent,
               :class_name => "::#{base_class.name}",
               :foreign_key => options[:parent_column],
               :inverse_of => (:children unless options[:polymorphic])

    include ClassMethods
    include InstanceMethods
    setup_ordered_tree_adapter
    setup_ordered_tree_callbacks
    setup_ordered_tree_validations
  end # def acts_as_ordered_tree

  # Mixed into both classes and instances to provide easy access to the column names
  module Columns
    extend ActiveSupport::Concern

    included do
      attr_protected depth_column, position_column if PROTECTED_ATTRIBUTES_SUPPORTED
    end

    def parent_column
      acts_as_ordered_tree_options[:parent_column]
    end

    def position_column
      acts_as_ordered_tree_options[:position_column]
    end

    def depth_column
      acts_as_ordered_tree_options[:depth_column] || nil
    end

    def children_counter_cache_column
      acts_as_ordered_tree_options[:counter_cache] || nil
    end

    def scope_column_names
      Array(acts_as_ordered_tree_options[:scope]).compact
    end
  end
end # module ActsAsOrderedTree

ActiveRecord::Base.extend(ActsAsOrderedTree)
