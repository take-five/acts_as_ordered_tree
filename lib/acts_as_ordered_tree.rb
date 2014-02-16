require 'active_record'

require 'acts_as_ordered_tree/version'
require 'acts_as_ordered_tree/tree'
require 'acts_as_ordered_tree/compatibility'

module ActsAsOrderedTree
  # @!attribute [r] ordered_tree
  #   @return [ActsAsOrderedTree::Tree] ordered tree object
  attr_reader :ordered_tree

  # == Usage
  #   class Category < ActiveRecord::Base
  #     acts_as_ordered_tree :parent_column => :parent_id,
  #                          :position_column => :position,
  #                          :depth_column => :depth,
  #                          :counter_cache => :children_count
  #   end
  def acts_as_ordered_tree(options = {})
    @ordered_tree = Tree.new(self, options)
    @ordered_tree.setup

    extend Columns
  end # def acts_as_ordered_tree

  # @deprecated Use `ordered_tree.columns` object
  module Columns
    extend ActiveSupport::Concern

    # @api private
    def self.deprecated_method(method, delegate)
      define_method(method) do
        ActiveSupport::Deprecation.warn("#{name}.#{method} is deprecated in favor of #{name}.ordered_tree.columns.#{delegate}", caller(1))

        ordered_tree.columns.send(delegate)
      end
    end

    deprecated_method :parent_column, :parent
    deprecated_method :position_column, :position
    deprecated_method :depth_column, :depth
    deprecated_method :children_counter_cache_column, :counter_cache
    deprecated_method :scope_column_name, :scope
  end
end # module ActsAsOrderedTree

ActiveRecord::Base.extend(ActsAsOrderedTree)
