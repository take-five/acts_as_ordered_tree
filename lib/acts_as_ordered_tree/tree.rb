# coding: utf-8

require 'acts_as_ordered_tree/compatibility'

require 'acts_as_ordered_tree/tree/callbacks'
require 'acts_as_ordered_tree/tree/columns'
require 'acts_as_ordered_tree/tree/children_association'
require 'acts_as_ordered_tree/tree/parent_association'
require 'acts_as_ordered_tree/tree/scopes'

require 'acts_as_ordered_tree/adapters'
require 'acts_as_ordered_tree/validators'

require 'acts_as_ordered_tree/instance_methods'
require 'acts_as_ordered_tree/perseverance'

module ActsAsOrderedTree
  # ActsAsOrderedTree::Tree
  class Tree
    # Default ordered tree options
    DEFAULT_OPTIONS = {
      :parent_column => :parent_id,
      :position_column => :position,
      :depth_column => :depth
    }.freeze

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
      @setup = false
    end

    # Builds associations, callbacks, validations etc.
    def setup
      return if already_setup?

      setup_associations
      setup_validations
      setup_callbacks
      protect_attributes columns.parent, columns.position
      include Scopes
      include InstanceMethods
      include Perseverance
    end

    private
    def already_setup?
      @klass.method_defined?(:ordered_tree) && @klass.ordered_tree.present?
    end

    def setup_associations
      @parent.build
      @children.build
    end

    def setup_validations
      if columns.scope?
        klass.validates_with Validators::ScopeValidator, :on => :update, :unless => :root?
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

    def include(m)
      klass.send(:include, m)
    end
  end
end