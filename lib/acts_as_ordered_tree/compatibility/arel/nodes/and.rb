module Arel
  module Nodes
    # Arel::Nodes::And is descendant of Arel::Nodes::Binary in Rails 3.0 only.
    # Here we patch Arel::Nodes::And#initialize so it can accept one Array argument (like in Rails 3.1+)
    class And < Binary
      def initialize(*args)
        super(*args.flatten)
      end
    end
  end
end