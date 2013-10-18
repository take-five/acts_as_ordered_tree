require "acts_as_ordered_tree/adapters/postgresql_adapter"

module ActsAsOrderedTree
  module ClassMethods
    extend ActiveSupport::Concern

    included do
      scope :preorder, -> { order(arel_table[position_column].asc) }
      scope :roots, -> { where(arel_table[parent_column].eq(nil)).preorder }

      # add +leaves+ scope only if counter_cache column present
      scope :leaves, -> { where(arel_table[children_counter_cache_column].eq(0)) } if
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

      def setup_ordered_tree_adapter #:nodoc:
        include "ActsAsOrderedTree::Adapters::#{connection.class.name.demodulize}".constantize
      rescue NameError, LoadError
        # ignore
      end

      def setup_ordered_tree_callbacks #:nodoc:
        define_model_callbacks :move, :reorder

        if depth_column
          before_create :set_depth!
          before_save   :set_depth!, :if => "#{parent_column}_changed?".to_sym
          around_move   :update_descendants_depth
        end

        if children_counter_cache_column
          around_move :update_counter_cache
        end

        unless scope_column_names.empty?
          before_save :set_scope!, :unless => :root?
        end

        after_save :move_to_root, :unless => [position_column, parent_column]
        after_save 'move_to_child_of(parent)', :if => parent_column, :unless => position_column
        after_save "move_to_child_with_index(parent, #{position_column})",
                   :if => "#{position_column} && (#{position_column}_changed? || #{parent_column}_changed?)"

        before_destroy :flush_descendants
        after_destroy "decrement_lower_positions(#{parent_column}_was, #{position_column}_was)", :if => position_column
      end

      def setup_ordered_tree_validations #:nodoc:
        unless scope_column_names.empty?
          validates_with Validators::ScopeValidator, :on => :update, :unless => :root?
        end

        # setup validations
        validates_with Validators::CyclicReferenceValidator, :on => :update, :if => :parent
      end
    end # module ClassMethods
  end # module ClassMethods
end # module ActsAsOrderedTree