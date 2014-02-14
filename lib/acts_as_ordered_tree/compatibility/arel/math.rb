module Arel
  module Math
    def *(other)
      Arel::Nodes::Multiplication.new(self, other)
    end

    def +(other)
      Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new(self, other))
    end

    def -(other)
      Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
    end

    def /(other)
      Arel::Nodes::Division.new(self, other)
    end
  end
end

module Arel
  module Attributes
    Attribute.class_eval do
      include Arel::Math
    end
  end
end