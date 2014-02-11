module TreeDefinition
  module Nodes
    class Abstract; end

    class Root < Abstract
      attr_accessor :children

      def initialize
        @children = []
      end
    end

    class Node < Abstract
      attr_accessor :name,
                    :attributes,
                    :children

      def initialize
        @attributes = []
        @children = []
      end
    end

    class Name < Abstract
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end

    class Any < Abstract
    end

    class Value < Abstract
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end

    class Attribute < Abstract
      attr_accessor :name,
                    :value
    end
  end
end