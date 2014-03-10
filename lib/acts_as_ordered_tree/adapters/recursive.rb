# coding: utf-8

require 'acts_as_ordered_tree/adapters/abstract'

module ActsAsOrderedTree
  module Adapters
    # Recursive adapter implements tree traversal in pure Ruby.
    class Recursive < Abstract
      def self_and_ancestors(node, &block)
        return none unless node

        ancestors_scope(node, :include_first => true, &block)
      end

      def ancestors(node, &block)
        ancestors_scope(node, :include_first => false, &block)
      end

      def descendants(node, &block)
        descendants_scope(node, :include_first => false, &block)
      end

      def self_and_descendants(node, &block)
        descendants_scope(node, :include_first => true, &block)
      end

      private
      def ancestors_scope(node, options, &block)
        traversal = Traversal.new(node, options, &block)
        traversal.follow :parent
        traversal.to_scope.reverse_order!
      end

      def descendants_scope(node, options, &block)
        return none unless node.persisted?

        traversal = Traversal.new(node, options, &block)
        traversal.follow :children
        traversal.to_scope
      end

      class Traversal
        delegate :klass, :to => :@start_record
        attr_accessor :include_first

        def initialize(start_record, options = {})
          @start_record = start_record
          @start_with = nil
          @order_values = []
          @where_values = []
          @include_first = options[:include_first]
          follow(options[:follow]) if options.key?(:follow)

          yield self if block_given?
        end

        def follow(association_name)
          @association = association_name

          self
        end

        def start_with(scope = nil, &block)
          @start_with = scope || block

          self
        end

        def order_siblings(*values)
          @order_values << values

          self
        end
        alias_method :order, :order_siblings

        def where(*values)
          @where_values << values

          self
        end

        def table
          klass.arel_table
        end

        def klass
          @start_record.class
        end

        def to_scope
          null_scope.records(to_enum.to_a)
        end

        private
        def each(&block)
          return unless validate_start_conditions

          yield @start_record if include_first

          expand(@start_record, &block)
        end

        def validate_start_conditions
          start_scope ? start_scope.exists? : true
        end

        def start_scope
          return nil unless @start_with

          if @start_with.is_a?(Proc)
            @start_with.call klass.where(klass.primary_key => @start_record.id)
          else
            @start_with
          end
        end

        def expand(record, &block)
          expand_association(record).each do |child|
            yield child

            expand(child, &block)
          end
        end

        def expand_association(record)
          if constraints?
            build_scope(record)
          else
            follow_association(record)
          end
        end

        def build_scope(record)
          scope = record.association(@association).scope

          @where_values.each { |v| scope = scope.where(*v) }
          scope = scope.except(:order).order(*@order_values.flatten) if @order_values.any?

          scope
        end

        def follow_association(record)
          Array.wrap(record.send(@association))
        end

        def null_scope
          klass.where(nil).extending(Relation::Preloaded)
        end

        def constraints?
          @where_values.any? || @order_values.any?
        end
      end
      private_constant :Traversal
    end # class Recursive
  end # module Adapters
end # module ActsAsOrderedTree