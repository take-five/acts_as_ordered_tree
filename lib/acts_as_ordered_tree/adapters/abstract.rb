# coding: utf-8

module ActsAsOrderedTree
  module Adapters
    class Abstract
      attr_reader :tree

      # @param [ActsAsOrderedTree::Tree] tree
      def initialize(tree)
        @tree = tree
      end

      protected
      def preloaded(records)
        tree.klass.where(nil).extending(Relation::Preloaded).records(records)
      end

      def none
        tree.klass.where(nil).none
      end
    end # class Abstract
  end # module Adapters
end # module ActsAsOrderedTree