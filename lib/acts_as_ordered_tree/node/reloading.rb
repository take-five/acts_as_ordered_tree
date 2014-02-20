# coding: utf-8

require 'acts_as_ordered_tree/compatibility'

module ActsAsOrderedTree
  class Node
    module Reloading
      Compatibility.version '< 4.0.0' do
        # Reloads node's attributes related to tree structure
        def reload(options = {})
          record.reload(options.merge(:select => tree_columns))
        end
      end

      Compatibility.version '>= 4.0.0' do
        # Reloads node's attributes related to tree structure
        def reload(options = {})
          record.association_cache.delete(:parent)
          record.association_cache.delete(:children)

          fresh_object = reload_scope(options).find(record.id)

          record.instance_eval do
            @attributes.update(fresh_object.instance_variable_get(:@attributes))
            @attributes_cache = {}
          end

          record
        end

        private
        def reload_scope(options)
          options ||= {}
          lock_value = options.fetch(:lock, false)
          record.class.unscoped.select(tree_columns).lock(lock_value)
        end
      end

      private
      def tree_columns
        tree.columns.to_a
      end
    end
  end
end