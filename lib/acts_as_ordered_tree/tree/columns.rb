# coding: utf-8

module ActsAsOrderedTree
  class Tree
    # Ordered tree columns store
    #
    # @example
    #   MyModel.tree.columns.parent # => "parent_id"
    #   MyModel.tree.columns.counter_cache # => nil
    #   MyModel.tree.columns.counter_cache? # => false
    class Columns
      # This error is raised when unknown column given in :scope option
      UnknownColumn = Class.new(StandardError)

      # @api private
      def self.column_accessor(*names)
        names.each do |name|
          define_method "#{name}=" do |value|
            @columns[name] = value.to_s if column_exists?(value)
          end
          private "#{name}=".to_sym

          define_method "#{name}?" do
            @columns[name].present?
          end

          define_method name do
            @columns[name]
          end
        end
      end

      # @!method parent
      # @!method parent?
      # @!method parent=(value)
      # @!method position
      # @!method position?
      # @!method position=(value)
      # @!method depth
      # @!method depth?
      # @!method depth=(value)
      # @!method counter_cache
      # @!method counter_cache?
      # @!method counter_cache=(value)
      # @!method scope
      # @!method scope?
      column_accessor :parent,
                      :position,
                      :depth,
                      :counter_cache,
                      :scope

      def initialize(klass, options = {})
        @klass = klass
        @columns = { :id => id }

        self.parent = options[:parent_column]
        self.position = options[:position_column]
        self.depth = options[:depth_column]
        self.counter_cache = counter_cache_name(options[:counter_cache])
        self.scope = options[:scope]
      end

      def [](name)
        @columns[name]
      end

      def id
        @klass.primary_key
      end

      # Returns array of columns names associated with ordered tree structure
      def to_a
        @columns.values.flatten.compact
      end

      private
      undef_method :scope=
      def scope=(value)
        columns = Array.wrap(value)

        unknown = columns.reject { |name| column_exists?(name) }

        raise UnknownColumn, "Unknown column#{'s' if unknown.size > 1} passed to :scope option: #{unknown.join(', ')}" if unknown.any?

        @columns[:scope] = columns.map(&:to_s)
      end

      def counter_cache_name(value)
        if value == true
          "#{@klass.name.demodulize.underscore.pluralize}_count"
        else
          value
        end
      end

      def column_exists?(name)
        name.present? && @klass.columns_hash.include?(name.to_s)
      end
    end # class Columns
  end # class Tree
end # module ActsAsOrderedTree