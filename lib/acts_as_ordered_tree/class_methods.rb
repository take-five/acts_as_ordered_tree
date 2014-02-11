# coding: utf-8

require 'acts_as_ordered_tree/adapters/postgresql_adapter'
require 'acts_as_ordered_tree/transaction/factory'

module ActsAsOrderedTree
  module ClassMethods
    extend ActiveSupport::Concern

    included do
      scope :preorder, -> { order(arel_table[position_column].asc) }
      scope :roots, -> { where(arel_table[parent_column].eq(nil)).preorder }

      # add +leaves+ scope only if counter_cache column present
      scope :leaves, -> { where(arel_table[children_counter_cache_column].eq(0)) } if
          children_counter_cache?
    end

    module ClassMethods
      # Returns the first root
      def root
        roots.first
      end

      private
      def children_counter_cache? #:nodoc:
        children_counter_cache_column && columns_hash.key?(children_counter_cache_column.to_s)
      end

      def setup_ordered_tree_adapter #:nodoc:
        include "ActsAsOrderedTree::Adapters::#{connection.class.name.demodulize}".constantize
      rescue NameError, LoadError
        # ignore
      end

      def setup_ordered_tree_callbacks #:nodoc:
        define_model_callbacks :move, :reorder

        around_save :save_ordered_tree_node
        around_destroy :destroy_ordered_tree_node
      end

      def setup_ordered_tree_validations #:nodoc:
        unless scope_column_names.empty?
          validates_with Validators::ScopeValidator, :on => :update, :unless => :root?
        end

        # setup validations
        validates_with Validators::CyclicReferenceValidator, :on => :update, :if => :parent

        #validates position_column,
        #          :numericality => {
        #              :only_integer => true,
        #              :greater_than => 0,
        #              :allow_blank => true
        #          }
      end
    end # module ClassMethods
  end # module ClassMethods
end # module ActsAsOrderedTree