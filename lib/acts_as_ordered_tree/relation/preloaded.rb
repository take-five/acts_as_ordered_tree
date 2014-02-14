# coding: utf-8

module ActsAsOrderedTree
  module Relation
    # AR::Relation extension which adds ability to explicitly set records
    #
    # @example
    #   records = MyModel.where(:parent_id => nil).to_a
    #   relation = MyModel.where(:parent_id => nil).
    #      extending(ActsAsOrderedTree::Relation::Preloaded).
    #      records(records)
    #   relation.to_a.should be records
    module Preloaded
      def records(records)
        self.where_values = build_where(:id => records.map(&:id).compact)

        @records = records
        @loaded = true

        self
      end

      # Reverse the existing order of records on the relation.
      def reverse_order
        (respond_to?(:spawn) ? spawn : clone).records(@records.reverse)
      end

      def reverse_order!
        @records.reverse!
      end
    end # module Preloaded
  end # module Relation
end # module ActsAsOrderedTree