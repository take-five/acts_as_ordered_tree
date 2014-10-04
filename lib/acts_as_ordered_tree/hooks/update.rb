# coding: utf-8

require 'active_support/concern'

module ActsAsOrderedTree
  module Hooks
    # This AR-hook is used in Move transactions to update parent_id, position
    # and other changed attributes using single SQL-query.
    #
    # @example
    #   class Category < ActiveRecord::Base
    #     include ActsAsOrderedTree::Hooks
    #   end
    #
    #   category = Category.first
    #   category.hook_update do |update|
    #     update.scope = Category.where(:parent_id => category.parent_id)
    #     update.values = { :name => Arel.sql('CASE WHEN parent_id IS NULL THEN name ELSE name || name END') }
    #
    #     # `update.update!` will be called instead of usual `AR::Persistence#update`
    #     record.save
    #   end
    #
    # @api private
    module Update
      extend ActiveSupport::Concern

      included do
        attr_accessor :__update_hook

        # Since rails 4.0 :update_record is used for actual updates
        # Since rails 4.0.x and 4.1.x (i really don't know which is x) :_update_record is used
        method_name = [:update_record, :_update_record].detect { |m| private_method_defined?(m) } || :update

        alias_method :update_without_hook, method_name
        alias_method method_name, :update_with_hook
      end

      def hook_update
        self.__update_hook = UpdateManager.new(self)
        yield __update_hook
      ensure
        self.__update_hook = nil
      end

      private
      def update_with_hook(*args)
        if __update_hook
          __update_hook.update!
        else
          update_without_hook(*args)
        end
      end

      class UpdateManager
        attr_reader :record
        attr_accessor :scope, :values

        def initialize(record)
          @record = record
          @values = {}
        end

        def update!
          scope.update_all(to_sql)
          record.reload
        end

        private
        def to_sql
          values.keys.map do |attr|
            name = attr.is_a?(Arel::Attributes::Attribute) ? attr.name : attr.to_s

            quoted = record.class.connection.quote_column_name(name)
            "#{quoted} = (#{value_of(attr)})"
          end.join(', ')
        end

        def value_of(attr)
          value = values[attr]
          value.respond_to?(:to_sql) ? value.to_sql : record.class.connection.quote(value)
        end
      end # class CustomUpdate
    end # module Update
  end # module Hooks
end # module ActsAsOrderedTree