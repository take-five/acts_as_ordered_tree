require "active_support/concern"
require "active_support/memoizable"

module ActsAsOrderedTree
  module List
    extend ActiveSupport::Concern

    included do
      include PatchedMethods
      scope :ordered, order(position_column)

      before_update :remove_from_old_list, :if => :parent_changed?
      before_update :add_to_list_bottom, :if => :parent_changed?
    end

    module InstanceMethods
      private
      def remove_from_old_list
        unchanged = self.class.find(id)
        unchanged.send(:decrement_positions_on_lower_items)

        nil
      end
    end

    # It should invoke callbacks, so we patch +acts_as_list+ methods
    module PatchedMethods
      private
      # This has the effect of moving all the higher items up one.
      def decrement_positions_on_higher_items(position)
        higher_than(position).each do |node|
          node.decrement!(position_column)
        end
      end

      # This has the effect of moving all the lower items up one.
      def decrement_positions_on_lower_items
        return unless in_list?
        lower_than(position).each do |node|
          node.decrement!(position_column)
        end
      end

      # This has the effect of moving all the higher items down one.
      def increment_positions_on_higher_items
        return unless in_list?

        higher_than(self[position_column]).each do |node|
          node.increment!(position_column)
        end
      end

      def increment_positions_on_all_items
        self_and_siblings.each do |sib|
          sib.increment!(position_column)
        end
      end

      def increment_positions_on_lower_items(position)
        lower_than(position).each do |node|
          node.increment!(position_column)
        end
      end

      def lower_than(position)
        acts_as_list_class.where(scope_condition).where("#{position_column} >= ?", position.to_i)
      end

      def higher_than(position)
        acts_as_list_class.where(scope_condition).where("#{position_column} < ?", position.to_i)
      end
    end
  end # module List
end # module ActsAsOrderedTree