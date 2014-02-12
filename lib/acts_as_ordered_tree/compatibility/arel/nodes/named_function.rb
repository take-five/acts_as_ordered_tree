module Arel
  module Nodes
    class NamedFunction < Arel::Nodes::Function
      attr_accessor :name, :distinct

      def initialize name, expr, aliaz = nil
        super(expr, aliaz)
        @name = name
      end
    end unless const_defined?(:NamedFunction)
  end
end
