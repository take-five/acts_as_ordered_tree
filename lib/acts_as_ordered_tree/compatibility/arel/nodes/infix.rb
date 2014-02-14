module Arel
  module Nodes
    class InfixOperation < Binary
      include Arel::Expressions
      include Arel::Predications
      include Arel::Math

      attr_reader :operator

      def initialize operator, left, right
        super(left, right)
        @operator = operator
      end
    end

    class Multiplication < InfixOperation
      def initialize left, right
        super(:*, left, right)
      end
    end

    class Division < InfixOperation
      def initialize left, right
        super(:/, left, right)
      end
    end

    class Addition < InfixOperation
      def initialize left, right
        super(:+, left, right)
      end
    end

    class Subtraction < InfixOperation
      def initialize left, right
        super(:-, left, right)
      end
    end
  end
end

module Arel
  module Visitors
    class ToSql < Arel::Visitors::Visitor
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