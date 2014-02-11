# coding: utf-8

module TreeDefinition
  module Visitors
    class Abstract
      def visit(o)
        method = "visit_#{o.class.name.gsub('::', '_')}"
        send(method, o)
      end
    end
  end
end