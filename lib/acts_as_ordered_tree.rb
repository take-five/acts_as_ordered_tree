require "enumerator"

require "active_record"
require "acts_as_list"
require "acts_as_tree"

require "acts_as_ordered_tree/version"
require "acts_as_ordered_tree/iterator"
require "acts_as_ordered_tree/tree"
require "acts_as_ordered_tree/list"

module ActsAsOrderedTree
  def acts_as_ordered_tree(options = {})
    configuration = configure_ordered_tree(options)

    acts_as_tree :foreign_key => parent_column,
                 :order => position_column,
                 :counter_cache => configuration[:counter_cache]

    acts_as_list :column => position_column,
                 :scope => parent_column

    include ActsAsOrderedTree::Tree
    include ActsAsOrderedTree::List
  end # def acts_as_ordered_tree

  private
      # Add ordered_tree configuration readers
  def configure_ordered_tree(options = {}) #:nodoc:
    configuration = { :foreign_key  => :parent_id ,
                      :order        => :position  }
    configuration.update(options) if options.is_a?(Hash)

    class_attribute :parent_column, :position_column

    self.parent_column   = configuration[:foreign_key].to_sym
    self.position_column = configuration[:order].to_sym

    configuration
  end # def configure_ordered_tree
end # module ActsAsOrderedTree

ActiveRecord::Base.extend(ActsAsOrderedTree)