require "active_record"
require "acts_as_ordered_tree/version"
require "acts_as_ordered_tree/class_methods"
require "acts_as_ordered_tree/instance_methods"
require "acts_as_ordered_tree/validators"

module ActsAsOrderedTree
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
      :class_name    => name,
      :foreign_key   => options[:parent_column],
      :order         => options[:position_column],
      :inverse_of    => (:parent unless options[:polymorphic]),
      :dependent     => :destroy
    }

    [:before_add, :after_add, :before_remove, :after_remove].each do |callback|
      has_many_children_options[callback] = options[callback] if options.key?(callback)
    end

    if scope_column_names.any?
      has_many_children_options[:conditions] = proc do
        [scope_column_names.map { |c| "#{c} = ?" }.join(' AND '),
         scope_column_names.map { |c| self[c] }]
      end
    end

    # create associations
    has_many   :children, has_many_children_options
    belongs_to :parent,
               :class_name => name,
               :foreign_key => options[:parent_column],
               :counter_cache => options[:counter_cache],
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
      attr_protected depth_column, position_column
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