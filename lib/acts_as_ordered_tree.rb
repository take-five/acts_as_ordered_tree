require 'acts_as_ordered_tree/version'
require 'active_support/lazy_load_hooks'

module ActsAsOrderedTree
  autoload :Tree, 'acts_as_ordered_tree/tree'

  # @!attribute [r] ordered_tree
  #   @return [ActsAsOrderedTree::Tree] ordered tree object

  # == Usage
  #   class Category < ActiveRecord::Base
  #     acts_as_ordered_tree :parent_column => :parent_id,
  #                          :position_column => :position,
  #                          :depth_column => :depth,
  #                          :counter_cache => :children_count
  #   end
  def acts_as_ordered_tree(options = {})
    Tree.setup!(self, options)
  end

  # @api private
  def self.extended(base)
    base.class_attribute :ordered_tree, :instance_writer => false
  end

  # Rebuild ordered tree structure for subclasses. It needs to be rebuilt
  # mainly because of :children and :parent associations, which are created
  # with option :class_name. It matters for class hierarchies without STI,
  # they can't work properly with associations inherited from superclass.
  #
  # @api private
  def inherited(subclass)
    super

    subclass.acts_as_ordered_tree(ordered_tree.options) if ordered_tree?
  end
end # module ActsAsOrderedTree

ActiveSupport.on_load(:active_record) do
  extend ActsAsOrderedTree
end