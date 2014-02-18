require 'acts_as_ordered_tree/version'
require 'active_support/lazy_load_hooks'

module ActsAsOrderedTree
  autoload :Tree, 'acts_as_ordered_tree/tree'

  # @!attribute [r] ordered_tree
  #   @return [ActsAsOrderedTree::Tree] ordered tree object

  # @api private
  def self.extended(base)
    base.class_attribute :ordered_tree, :instance_writer => false
  end

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
end # module ActsAsOrderedTree

ActiveSupport.on_load(:active_record) do
  extend ActsAsOrderedTree
end