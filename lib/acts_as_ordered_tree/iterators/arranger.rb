# coding: utf-8

module ActsAsOrderedTree
  module Iterators
    # @api private
    class Arranger
      include Enumerable

      delegate :each, :to => :arrange

      def initialize(collection)
        @collection = collection
        @cache = Hash.new
      end

      def arrange
        @collection.each_with_object(Hash.new) do |node, result|
          @cache[node.id] ||= node

          insertion_point = result

          ancestors(node).each { |a| insertion_point = (insertion_point[a] ||= {}) }

          insertion_point[node] = {}
        end
      end

      private
      def ancestors(node)
        parent = @cache[node.ordered_tree_node.parent_id]
        parent ? ancestors(parent) + [parent] : []
      end
    end # class Arranger
  end # module Iterators
end # module ActsAsOrderedTree