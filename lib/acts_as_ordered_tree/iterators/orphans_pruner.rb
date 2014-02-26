# coding: utf-8

module ActsAsOrderedTree
  module Iterators
    # @api private
    class OrphansPruner
      include Enumerable

      def initialize(collection)
        @collection = collection
        @cache = Hash.new
        @level = nil # minimal node level
      end

      def each
        return to_enum unless block_given?

        prepare if @cache.empty?

        @collection.each do |node|
          if orphan?(node)
            discard(node.id)
          else
            yield node
          end
        end
      end

      private
      def orphan?(node)
        !has_parent?(node) && node.level > @level
      end

      def has_parent?(node)
        @cache.key?(node.ordered_tree_node.parent_id)
      end

      def prepare
        @collection.each do |node|
          @cache[node.id] = []

          if has_parent?(node)
            @cache[node.ordered_tree_node.parent_id] << node.id
          else
            @level = [@level, node.level].compact.min
          end
        end
      end

      def discard(id)
        if @cache.key?(id)
          @cache[id].each { |k| discard(k) }
          @cache.delete(id)
        end
      end
    end # class OrphansPruner
  end # module Iterators
end # module ActsAsOrderedTree