module Arel
  module Nodes
    class With < Arel::Nodes::Unary
      alias children expr
    end

    class WithRecursive < With; end

    class SelectStatement < Arel::Nodes::Node
      attr_accessor :with
    end
  end

  class SelectManager < Arel::TreeManager
    def with *subqueries
      if subqueries.first.is_a? Symbol
        node_class = Nodes.const_get("With#{subqueries.shift.to_s.capitalize}")
      else
        node_class = Nodes::With
      end
      @ast.with = node_class.new(subqueries.flatten)

      self
    end
  end

  module Visitors
    class ToSql < Arel::Visitors::Visitor
      private
      def visit_Arel_Nodes_SelectStatement o
        [
            (visit o.with if o.with),
            o.cores.map { |x| visit_Arel_Nodes_SelectCore x }.join,
            ("ORDER BY #{o.orders.map { |x| visit x }.join(', ')}" unless o.orders.empty?),
            (visit(o.limit) if o.limit),
            (visit(o.offset) if o.offset),
            (visit(o.lock) if o.lock),
        ].compact.join ' '
      end

      def visit_Arel_Nodes_With o, *a
        "WITH #{o.children.map { |x| visit x, *a }.join(', ')}"
      end

      def visit_Arel_Nodes_WithRecursive o, *a
        "WITH RECURSIVE #{o.children.map { |x| visit x, *a }.join(', ')}"
      end
    end
  end
end