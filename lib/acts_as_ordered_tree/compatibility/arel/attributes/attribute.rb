require 'acts_as_ordered_tree/compatibility/arel/math'

module Arel
  module Attributes
    class Attribute < Attribute.superclass
      include Arel::Math
    end
  end
end
