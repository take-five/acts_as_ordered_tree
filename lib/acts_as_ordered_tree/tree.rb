# coding: utf-8

require 'acts_as_ordered_tree/compatibility'

require 'acts_as_ordered_tree/tree/callbacks'
require 'acts_as_ordered_tree/tree/columns'
require 'acts_as_ordered_tree/tree/children_association'
require 'acts_as_ordered_tree/tree/deprecated_columns_accessors'
require 'acts_as_ordered_tree/tree/parent_association'
require 'acts_as_ordered_tree/tree/perseverance'
require 'acts_as_ordered_tree/tree/scopes'

require 'acts_as_ordered_tree/hooks'

require 'acts_as_ordered_tree/adapters'
require 'acts_as_ordered_tree/validators'

require 'acts_as_ordered_tree/instance_methods'

module ActsAsOrderedTree
  # ActsAsOrderedTree::Tree
  class Tree
    # Default ordered tree options
    DEFAULT_OPTIONS = {
      :parent_column => :parent_id,
      :position_column => :position,
      :depth_column => :depth
    }.freeze

    PROTECTED_ATTRIBUTES = :left_sibling, :left_sibling_id,
                           :higher_item, :higher_item_id,
                           :right_sibling, :right_sibling_id,
                           :lower_item, :lower_item_id

    attr_reader :klass

    # @!attribute [r] columns
    #   Columns information aggregator
    #
    #   @return [ActsAsOrderedTree::Tree::Columns] column object
    attr_reader :columns

    # @!attribute [r] callbacks
    #   :before_add, :after_add, :before_remove and :after_remove callbacks storage
    #
    #   @return [ActsAsOrderedTree::Tree::Callbacks] callbacks object
    attr_reader :callbacks

    # @!attribute [r] adapter
    #   Ordered tree adapter which contains implementation of some traverse methods
    #
    #   @return [ActsAsOrderedTree::Adapters::Abstract] adapter object
    attr_reader :adapter

    # @!attribute [r] options
    #   Ordered tree options
    #
    #   @return [Hash]
    attr_reader :options

    # Create and setup tree object
    #
    # @param [Class] klass
    # @param [Hash] options
    def self.setup!(klass, options)
      klass.ordered_tree = new(klass, options).setup
    end

    # @param [Class] klass
    # @param [Hash] options
    def initialize(klass, options)
      @klass = klass
      @options = DEFAULT_OPTIONS.merge(options).freeze
      @columns = Columns.new(klass, @options)
      @callbacks = Callbacks.new(klass, @options)
      @children = ChildrenAssociation.new(self)
      @parent = ParentAssociation.new(self)
      @adapter = Adapters.lookup(klass.connection.adapter_name).new(self)
    end

    # Builds associations, callbacks, validations etc.
    def setup
      setup_associations
      setup_once

      self
    end

    # Returns Class object which will be used for associations,
    # scopes and tree traversals.
    #
    # @return [Class]
    def base_class
      if klass.finder_needs_type_condition?
        klass.base_class
      else
        klass
      end
    end

    private
    def already_setup?
      klass.ordered_tree?
    end

    def setup_once
      return if already_setup?

      setup_validations
      setup_callbacks
      protect_attributes columns.parent, columns.position, *PROTECTED_ATTRIBUTES

      klass.class_eval do
        extend Scopes
        extend DeprecatedColumnsAccessors

        include InstanceMethods
        include Perseverance
        include Hooks
      end
    end

    def setup_associations
      @parent.build
      @children.build
    end

    def setup_validations
      if columns.scope?
        klass.validates_with Validators::ScopeValidator, :on => :update, :if => :parent
      end

      klass.validates_with Validators::CyclicReferenceValidator, :on => :update, :if => :parent
    end

    def setup_callbacks
      klass.define_model_callbacks(:move, :reorder)
      klass.around_save(:save_ordered_tree_node)
      klass.around_destroy(:destroy_ordered_tree_node)
    end

    def protect_attributes(*attributes)
      Compatibility.version '< 4.0.0' do
        klass.attr_protected *attributes
      end
    end
  end
end