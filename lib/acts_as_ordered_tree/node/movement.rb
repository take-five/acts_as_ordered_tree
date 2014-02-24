# coding: utf-8

require 'acts_as_ordered_tree/persevering_transaction'

module ActsAsOrderedTree
  class Node
    # @api private
    class Movement
      attr_reader :node, :options

      delegate :record, :position, :position=, :to => :node

      def initialize(node, target = nil, options = {}, &block)
        @node, @options, @block = node, options, block
        @_target = target
      end

      def parent=(id_or_record)
        if id_or_record.is_a?(ActiveRecord::Base)
          record.parent = id_or_record
        else
          node.parent_id = id_or_record
        end
      end

      def start
        transaction do
          record.reload

          @block[self] if @block

          record.save
        end
      end

      def target
        return @target if defined?(@target)

        # load target
        @target = case @_target
                    when ActiveRecord::Base, nil
                      @_target.lock!
                    when nil
                      nil
                    else
                      scope = node.scope.lock

                      if options.fetch(:strict, false)
                        scope.find(@_target)
                      else
                        scope.where(:id => @_target).first
                      end
                  end.try(:ordered_tree_node)
      end

      private
      def transaction(&block)
        PerseveringTransaction.new(record.class.connection).start(&block)
      end
    end # class Movement
  end # class Node
end # module ActsAsOrderedTree