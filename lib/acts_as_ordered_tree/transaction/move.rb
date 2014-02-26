# coding: utf-8

require 'acts_as_ordered_tree/transaction/update'

module ActsAsOrderedTree
  module Transaction
    class Move < Update
      around :callbacks
      before 'trigger_callback(:before_remove, from.parent)'
      before 'trigger_callback(:before_add, to.parent)'

      after :update_descendants_depth, :if => [
          'transition.movement?',
          'tree.columns.depth?',
          'transition.level_changed?',
          'record.children.size > 0'
      ]

      after 'trigger_callback(:after_add, to.parent)'
      after 'trigger_callback(:after_remove, from.parent)'
      after 'transition.update_counters'

      finalize

      private
      def callbacks
        record.run_callbacks :move do
          record.with_update_scope do |update|
            update.scope = scope
            update.set update_values

            yield

            record.reload
          end
        end
      end

      def update_values
        updates = Hash[
            position => position_value,
            parent_id => parent_id_value
        ]

        updates[depth] = depth_value if tree.columns.depth? && transition.level_changed?

        changed_attributes.each { |attr| updates[attr] = attribute_value(attr) }

        updates
      end

      # Records to be updated
      def scope
        filter = (id == record.id) | (parent_id == from.parent_id) | (parent_id == to.parent_id)
        node.scope.where(filter.to_sql)
      end

      def parent_id_value
        switch.when(id == record.id, to.parent_id).else(parent_id)
      end

      def position_value
        switch.
            when(id == record.id).
                then(@to.position).
            # decrement lower positions in old parent
            when((parent_id == from.parent_id) & (position > from.position)).
                then(position - 1).
            # increment positions in new parent
            when((parent_id == to.parent_id) & (position >= to.position)).
                then(position + 1).
            else(position)
      end

      def depth_value
        switch.
            when(id == record.id, to.depth).
            else(depth)
      end

      def attribute_value(attr)
        attr_value = record.read_attribute(attr)
        quoted = record.class.connection.quote(attr_value)

        switch.
            when(id == record.id).then(Arel.sql(quoted)).
            else(attribute(attr))
      end

      def changed_attributes
        record.changed - (tree.columns.to_a - tree.columns.scope)
      end

      def update_descendants_depth
        record.descendants.update_all set depth => depth + (to.depth - from.depth)
      end
    end
  end
end