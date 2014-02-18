# coding: utf-8

module ActsAsOrderedTree
  class Tree
    class Association
      attr_reader :tree

      delegate :klass, :to => :tree

      def initialize(tree)
        @tree = tree
      end

      protected
      def class_name
        if klass.finder_needs_type_condition?
          "::#{klass.base_class.name}"
        else
          "::#{klass.name}"
        end
      end
    end # class Association
  end # class Tree
end # module ActsAsOrderedTree