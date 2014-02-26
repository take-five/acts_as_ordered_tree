# coding: utf-8

require 'active_support/concern'

module ActsAsOrderedTree
  class Tree
    # Included into AR::Base subclass this module allows
    # to update multiple records at once when `record.save` called.
    #
    # This hack is used in Move transactions to update parent_id, position
    # and other changed attributes using single SQL-query.
    #
    # @example
    #   class Category < ActiveRecord::Base
    #     include ActsAsOrderedTree::Node::UpdateScope
    #   end
    #
    #   category = Category.first
    #   category.with_update_scope do |update|
    #     update.scope = Category.where(:parent_id => category.parent_id)
    #     update.set :name => Arel.sql('CASE WHEN parent_id IS NULL THEN name ELSE name || name END')
    #
    #     # `update.update!` will be called instead of usual `AR::Persistence#update`
    #     record.save
    #   end
    #
    # @api private
    module UpdateScope
      extend ActiveSupport::Concern

      included do
        attr_accessor :__update_scope

        # Since rails 4.0 :update_record used for actual updates
        method_name = private_method_defined?(:update_record) ? :update_record : :update

        alias_method :update_without_scope, method_name
        alias_method method_name, :update_with_scope
      end

      def with_update_scope
        self.__update_scope = Builder.new(self)
        yield __update_scope
      ensure
        self.__update_scope = nil
      end

      private
      def update_with_scope(*args)
        if __update_scope
          __update_scope.update!
        else
          update_without_scope(*args)
        end
      end

      class Builder
        attr_reader :record
        attr_accessor :scope

        def initialize(record)
          @record = record
          @attributes = {}
        end

        def set(attributes)
          @attributes.merge!(attributes)
        end

        def update!
          scope.update_all(to_sql)
        end

        private
        def to_sql
          @attributes.map do |attr, value|
            name = attr.is_a?(Arel::Attributes::Attribute) ? attr.name : attr.to_s

            quoted = record.class.connection.quote_column_name(name)
            "#{quoted} = (#{value.respond_to?(:to_sql) ? value.to_sql : record.class.connection.quote(value)})"
          end.join(', ')
        end
      end
    end # module UpdateScope
  end # class Tree
end # module ActsAsOrderedTree