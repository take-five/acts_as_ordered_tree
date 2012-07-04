module ActsAsOrderedTree
  module ClassMethods
    extend ActiveSupport::Concern

    included do
      scope :preorder, order(arel_table[position_column].asc)
      scope :roots, where(arel_table[parent_column].eq(nil)).preorder

      # add +leaves+ scope only if counter_cache column present
      scope :leaves, where(arel_table[children_counter_cache_column].eq(0)) if
          children_counter_cache?

      # when default value for counter_cache is absent we should set it manually
      before_create "self.#{children_counter_cache_column} = 0" if children_counter_cache?
    end

    module ClassMethods
      # Returns the first root
      def root
        roots.first
      end

      private
      def children_counter_cache? #:nodoc:
        children_counter_cache_column && columns_hash.key?(children_counter_cache_column.to_s)
      end
    end # module ClassMethods
  end # module ClassMethods
end # module ActsAsOrderedTree