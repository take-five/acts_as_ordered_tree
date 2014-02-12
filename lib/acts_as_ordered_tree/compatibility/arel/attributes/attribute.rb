require 'acts_as_ordered_tree/compatibility/arel/math'

module Arel
  module Attributes
    Attribute.class_eval do
      include Arel::Math
    end
  end
end
