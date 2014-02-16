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

          scope = record.class.unscoped.select(tree_columns)

          fresh_object =
              if options && options[:lock]
                scope.lock.find(record.id)
              else
                scope.find(record.id)
              end

          record.instance_eval do
            @attributes.update(fresh_object.instance_variable_get(:@attributes))
            @attributes_cache = {}
          end
        end
      end

      private
      def tree_columns
        tree.columns.to_a
      end
    end
  end
end