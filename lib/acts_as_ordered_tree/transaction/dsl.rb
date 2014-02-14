# coding: utf-8

require 'active_support/core_ext/string/inflections'

module Arel
  module Nodes
    # Case node
    #
    # @example
    #   switch.when(table[:x].gt(1), table[:y]).else(table[:z])
    #   # CASE WHEN "table"."x" > 1 THEN "table"."y" ELSE "table"."z" END
    #   switch.when(table[:x].gt(1)).then(table[:y]).else(table[:z])
    class Case < Arel::Nodes::Node
      include Arel::Expression
      include Arel::Predications

      attr_reader :conditions, :default

      def initialize
        @conditions = []
        @default = nil
      end

      def when(condition, expression = nil)
        @conditions << When.new(condition, expression)
        self
      end

      def then(expression)
        @conditions.last.right = expression
        self
      end

      def else(expression)
        @default = Else.new(expression)
        self
      end
    end

    class When < Arel::Nodes::Binary
    end

    class Else < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql < Arel::Visitors::Visitor
      private
      def visit_Arel_Nodes_Case o, *a
        conditions = o.conditions.map { |x| visit x, *a }.join(' ')
        default = o.default && visit(o.default, *a)

        "CASE #{[conditions, default].compact.join(' ')} END"
      end

      def visit_Arel_Nodes_When o, *a
        "WHEN #{visit o.left} THEN #{visit o.right, *a}"
      end

      def visit_Arel_Nodes_Else o, *a
        "ELSE #{visit o.expr, *a}"
      end
    end

    class DepthFirst < Arel::Visitors::Visitor
      def visit_Arel_Nodes_Case o, *a
        visit o.conditions, *a
        visit o.default, *a
      end
      alias :visit_Arel_Nodes_When :binary
      alias :visit_Arel_Nodes_Else :unary
    end
  end
end

module ActsAsOrderedTree
  module Transaction
    # Simple DSL to generate complex UPDATE queries.
    # Requires +record+ method.
    #
    # @api private
    module DSL
      module Shortcuts
        INFIX_OPERATIONS = Hash[
            :==   => Arel::Nodes::Equality,
            :'!=' => Arel::Nodes::NotEqual,
            :>    => Arel::Nodes::GreaterThan,
            :>=   => Arel::Nodes::GreaterThanOrEqual,
            :<    => Arel::Nodes::LessThan,
            :<=   => Arel::Nodes::LessThanOrEqual,
            :=~   => Arel::Nodes::Matches,
            :'!~' => Arel::Nodes::DoesNotMatch,
            :|    => Arel::Nodes::Or
        ]

        # generate subclasses and methods
        INFIX_OPERATIONS.each do |operator, klass|
          subclass = Class.new(klass) { include Shortcuts }
          const_set(klass.name.demodulize, subclass)
          INFIX_OPERATIONS[operator] = subclass

          define_method(operator) do |arg|
            subclass.new(self, arg)
          end
        end

        And = Class.new(Arel::Nodes::And) { include Shortcuts }

        def &(arg)
          And.new [self, arg]
        end
      end

      Attribute = Class.new(Arel::Attributes::Attribute) { include Shortcuts }
      SqlLiteral = Class.new(Arel::Nodes::SqlLiteral) { include Shortcuts }

      NamedFunction = Class.new(Arel::Nodes::NamedFunction) {
        include Shortcuts
        include Arel::Math
      }

      # Create Arel::Nodes::Case node
      def switch
        Arel::Nodes::Case.new
      end

      # Create assignments expression for UPDATE statement
      #
      # @example
      #   Model.where(:parent_id => nil).update_all(set :name => switch.when(x < 10).then('OK').else('TOO LARGE'))
      #
      # @param [Hash] assignments
      def set(assignments)
        assignments.map do |attr, value|
          next unless attr.present?

          name = attr.is_a?(Arel::Attributes::Attribute) ? attr.name : attr.to_s

          quoted = record.class.connection.quote_column_name(name)
          "#{quoted} = (#{value.to_sql})"
        end.join(', ')
      end

      def attribute(name)
        name && Attribute.new(table, name.to_sym)
      end

      def expression(expr)
        SqlLiteral.new(expr.to_s)
      end

      def id
        attribute(record.class.primary_key)
      end

      def parent_id
        attribute(record.class.parent_column)
      end

      def position
        attribute(record.class.position_column)
      end

      def depth
        attribute(record.class.depth_column)
      end

      def table
        record.class.arel_table
      end

      def method_missing(id, *args)
        if args.length > 0
          # function
          NamedFunction.new(id.to_s.upcase, args)
        else
          super
        end
      end
    end # module DSL
  end # module Transaction
end # module ActsAsOrderedTree