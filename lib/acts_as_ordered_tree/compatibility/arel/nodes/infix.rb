require 'acts_as_ordered_tree/compatibility/arel/math'

module Arel
  module Nodes
    unless const_defined?(:InfixOperation)
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
end