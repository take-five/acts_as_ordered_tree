# coding: utf-8

require 'acts_as_ordered_tree/iterators/arranger'
require 'acts_as_ordered_tree/iterators/orphans_pruner'

module ActsAsOrderedTree
  module Relation
    # This AR::Relation extension allows to arrange collection into
    # Hash of nested Hashes
    module Arrangeable
      # Arrange associated collection into a nested hash of the form
      # {node => children}, where children = {} if the node has no children.
      #
      # It is possible to discard orphaned nodes (nodes which don't have
      # corresponding parent node in this collection) by passing `:orphans => :discard`
      # as option.
      #
      # @param [Hash] options
      # @option options [:discard, nil] :orphans
      # @return [Hash<ActiveRecord::Base => Hash>]
      def arrange(options = {})
        collection = self

        if options && options[:orphans] == :discard
          collection = Iterators::OrphansPruner.new(self)
        end

        @arranger ||= Iterators::Arranger.new(collection)
        @arranger.arrange
      end
    end
  end
end