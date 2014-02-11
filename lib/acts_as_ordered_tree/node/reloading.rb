# coding: utf-8

module ActsAsOrderedTree
  module Node::Reloading
    # Reloads node's attributes related to tree structure
    def reload(options = {})
      if supports_partial_reloading?
        record.reload(options.merge(:select => tree_columns))
      else
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
    # Since Rails 4.0 there is no possibility to reload only certain attributes
    def supports_partial_reloading?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def tree_columns
      Array[
          record.class.primary_key,
          record.class.parent_column,
          record.class.position_column,
          record.class.depth_column,
          record.class.children_counter_cache_column
      ].compact
    end
  end
end