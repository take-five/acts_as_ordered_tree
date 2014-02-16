module Arel
  module AliasPredication
    def as other
      Nodes::As.new self, Nodes::SqlLiteral.new(other)
    end
  end

  module Predications
    def as other
      Nodes::As.new self, Nodes::SqlLiteral.new(other)
    end
  end
end