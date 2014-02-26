# coding: utf-8

module ActsAsOrderedTree
  module Iterators
    # @api private
    class LevelCalculator
      include Enumerable

      def initialize(collection)
        @collection = collection
        @level = nil # minimal nodes level (first item level)
      end

      def each(&block)
        return to_enum unless block_given?

        if @collection.klass.ordered_tree.columns.depth?
          each_with_cached_level(&block)
        else
          each_without_cached_level(&block)
        end
      end

      private
      def each_with_cached_level
        @collection.each { |node| yield node, node.level }
      end

      def each_without_cached_level
        path = []

        @collection.each do |node|
          parent_id = node.ordered_tree_node.parent_id

          @level ||= node.level
          path << parent_id if path.empty?

          if parent_id != path.last
            # parent changed
            if path.include?(parent_id) # ascend
              path.pop while path.last != parent_id
            else # descend
              path << parent_id
            end
          end

          yield node, @level + path.length - 1
        end
      end
    end # class LevelCalculator
  end
end