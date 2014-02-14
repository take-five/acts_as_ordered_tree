module Arel
  module Nodes
    class NamedFunction < Arel::Nodes::Function
      attr_accessor :name, :distinct

      def initialize name, expr, aliaz = nil
        super(expr, aliaz)
        @name = name
      end
    end
  end
end

module Arel
  module Visitors
    class ToSql < Arel::Visitors::Visitor
      def visit_Arel_Nodes_NamedFunction o, *a
        "#{o.name}(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map { |x|
          visit x, *a
        }.join(', ')})#{o.alias ? " AS #{visit o.alias, *a}" : ''}"
      end
    end
  end
end