module Arel
  class Table
    def [] name
      ::Arel::Attribute.new self, name
    end
  end
end