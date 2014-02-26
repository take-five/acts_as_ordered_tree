# coding: utf-8

require 'acts_as_ordered_tree/iterators/level_calculator'
require 'acts_as_ordered_tree/iterators/orphans_pruner'

module ActsAsOrderedTree
  module Relation
    module Iterable
      # Iterates over tree elements and determines the current level in the tree.
      # Only accepts default ordering, no orphans allowed (they considered as root elements).
      # This method is efficient on trees that don't cache level.
      #
      # @example
      #   node.descendants.each_with_level do |descendant, level|
      #   end
      #
      # @return [Enumerator] if block is not given
      def each_with_level(&block)
        Iterators::LevelCalculator.new(self).each(&block)
      end

      # Iterates over tree elements but discards any orphaned nodes (e.g. nodes
      # which have a parent, but parent isn't in current collection).
      #
      # @example Collection with orphaned nodes
      #   # Assume we have following tree:
      #   # root 1
      #   #   child 1
      #   # root 2
      #   #   child 2
      #
      #   MyModel.where('id != ?', root_1.id).extending(Iterable).each_without_orphans.to_a
      #   # => [root_2, child_2]
      #
      # @return [Enumerator] if block is not given
      def each_without_orphans(&block)
        Iterators::OrphansPruner.new(self).each(&block)
      end
    end # module Iterable
  end # module Relation
end # module ActsAsOrderedTree