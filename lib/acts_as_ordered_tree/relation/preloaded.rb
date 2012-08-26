require "acts_as_ordered_tree/relation/base"

module ActsAsOrderedTree
  module Relation
    # Common relation, but with already loaded records
    class Preloaded < Base
      # Set loaded records to +records+
      def records(records)
        relation = clone
        relation.instance_variable_set :@records, records
        relation.instance_variable_set :@loaded,  true
        relation
      end
    end
  end
end