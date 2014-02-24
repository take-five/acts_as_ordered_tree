# coding: utf-8

require 'acts_as_ordered_tree/node/predicates'

module ActsAsOrderedTree
  class Node
    module Siblings
      include Predicates

      # Returns collection of all children of the parent, including self
      #
      # @return [ActiveRecord::Relation]
      def self_and_siblings
        scope.where( tree.columns.parent => parent_id ).preorder
      end

      # Returns collection of all children of the parent, except self
      #
      # @return [ActiveRecord::Relation]
      def siblings
        self_and_siblings.where( table[tree.columns.id].not_eq(id) )
      end

      # Returns siblings lying to the left of (upper than) current node.
      #
      # @return [ActiveRecord::Relation]
      def left_siblings
        siblings.where( table[tree.columns.position].lteq(position) )
      end
      alias :higher_items :left_siblings

      # Returns a left (upper) sibling of node.
      #
      # @return [ActiveRecord::Base, nil]
      def left_sibling
        higher_items.last
      end
      alias :higher_item :left_sibling

      # Set node new left (upper) sibling.
      # Just changes node's parent_id and position attributes.
      #
      # @param [ActiveRecord::Base] node new left sibling
      # @raise [ActiveRecord::AssociationTypeMismatch] if +node+ class does not
      #   match current node class.
      def left_sibling=(node)
        return node if record == node

        to = validate_sibling!(node)

        self.position = higher_than?(node) ? to.position : to.position + 1
        self.parent_id = to.parent_id

        node
      end
      alias :higher_item= :left_sibling=

      # Set node new left sibling by its ID.
      # Changes node's parent_id and position.
      #
      # @param [Fixnum] id new left sibling ID
      # @raise [ActiveRecord::RecordNotFound] if given +id+ was not found
      def left_sibling_id=(id)
        assign_sibling_by_id(id, :left)
      end
      alias :higher_item_id= :left_sibling_id=

      # Returns siblings lying to the right of (lower than) current node.
      #
      # @return [ActiveRecord::Relation]
      def right_siblings
        siblings.where( table[tree.columns.position].gteq(position) )
      end
      alias :lower_items :right_siblings

      # Returns a right (lower) sibling of the node
      #
      # @return [ActiveRecord::Base, nil]
      def right_sibling
        right_siblings.first
      end
      alias :lower_item :right_sibling

      # Set node new right (lower) sibling.
      # Just changes node's parent_id and position attributes.
      #
      # @param [ActiveRecord::Base] node new right sibling
      # @raise [ActiveRecord::AssociationTypeMismatch] if +node+ class does not
      #   match current node class.
      def right_sibling=(node)
        to = validate_sibling!(node)

        self.position = higher_than?(node) ? to.position - 1 : to.position
        self.parent_id = to.parent_id

        node
      end
      alias :lower_item= :right_sibling=

      # Set node new right sibling by its ID.
      # Changes node's parent_id and position.
      #
      # @param [Fixnum] id new right sibling ID
      # @raise [ActiveRecord::RecordNotFound] if given +id+ was not found
      def right_sibling_id=(id)
        assign_sibling_by_id(id, :right)
      end
      alias :lower_item_id= :right_sibling_id=

      private
      def higher_than?(other)
        same_parent?(other) && position < other.ordered_tree_node.position
      end

      # Raises exception if +other+ is kind of wrong class
      #
      # @return [ActsAsOrderedTree::Node]
      def validate_sibling!(other)
        unless other.is_a?(tree.base_class)
          message = "#{tree.base_class.name} expected, got #{other.class.name}"
          raise ActiveRecord::AssociationTypeMismatch, message
        end

        other.ordered_tree_node
      end

      # @api private
      def assign_sibling_by_id(id, position)
        node = tree.base_class.find(id)

        case position
          when :left, :higher then self.left_sibling = node
          when :right, :lower then self.right_sibling = node
          else raise RuntimeError, 'Unknown sibling position'
        end
      end
    end # module Siblings
  end # class Node
end # module ActsAsOrderedTree