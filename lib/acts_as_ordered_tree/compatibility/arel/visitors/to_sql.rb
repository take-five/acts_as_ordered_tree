module Arel
  module Visitors
    class ToSql < Arel::Visitors::Visitor
      unless method_defined?(:visit_Arel_Nodes_InfixOperation)
        def visit_Arel_Nodes_InfixOperation o, *a
          "#{visit o.left, *a} #{o.operator} #{visit o.right, *a}"
        end

        alias :visit_Arel_Nodes_Addition       :visit_Arel_Nodes_InfixOperation
        alias :visit_Arel_Nodes_Subtraction    :visit_Arel_Nodes_InfixOperation
        alias :visit_Arel_Nodes_Multiplication :visit_Arel_Nodes_InfixOperation
        alias :visit_Arel_Nodes_Division       :visit_Arel_Nodes_InfixOperation
      end
    end
  end
end