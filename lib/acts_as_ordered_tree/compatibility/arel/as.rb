module Arel
  class SelectManager < Arel::TreeManager
    def as other
      Nodes::TableAlias.new(Nodes::SqlLiteral.new(other), Nodes::Grouping.new(@ast))
    end
  end
end