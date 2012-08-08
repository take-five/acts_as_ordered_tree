require "active_record"
require "acts_as_ordered_tree/version"
require "acts_as_ordered_tree/class_methods"
require "acts_as_ordered_tree/fake_scope"
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
      :inverse_of    => (:parent unless options[:polymorphic])
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

    define_model_callbacks :move, :reorder

    include ClassMethods
    include InstanceMethods

    # protect position&depth from mass-assignment
    attr_protected depth_column, position_column

    if depth_column
      before_create :set_depth!
      before_save :set_depth!, :if => "#{parent_column}_changed?"
    end

    unless scope_column_names.empty?
      before_save :set_scope!, :unless => :root?
      validates_with Validators::ScopeValidator, :on => :update, :unless => :root?
    end

    after_save "move_to_child_with_index(parent, #{position_column})", :if => position_column
    after_save :move_to_root, :unless => [position_column, parent_column]
    after_save 'move_to_child_of(parent)', :if => parent_column, :unless => position_column

    before_destroy :destroy_descendants
    after_destroy "decrement_lower_positions(#{parent_column}_was, #{position_column}_was)", :if => position_column

    # setup validations
    validates_with Validators::CyclicReferenceValidator, :on => :update, :if => :parent
  end # def acts_as_ordered_tree

  # Mixed into both classes and instances to provide easy access to the column names
  module Columns
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