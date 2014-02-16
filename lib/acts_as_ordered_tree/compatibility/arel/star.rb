module Arel
  def self.star
    sql '*'
  end

  module Visitors
    class ToSql < Arel::Visitors::Visitor
      private
      def quote_column_name name
        @quoted_columns[name] ||= Arel::Nodes::SqlLiteral === name ? name : @connection.quote_column_name(name)
      end
    end
  end
end