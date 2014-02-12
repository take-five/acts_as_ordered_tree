# coding: utf-8

module ActsAsOrderedTree
  module Relation
    # This AR::Relation extension allows to arrange collection into
    # Hash of nested Hashes
    module Arrangeable
      # Arrange associated collection into a nested hash of the form
      # {node => children}, where children = {} if the node has no children.
      def arrange(options = {})
        @arranger ||= Arranger.new(self, options)
        @arranger.arrange
      end

      # @api private
      class Arranger
        attr_reader :collection, :cache

        def initialize(collection, options = {})
          @collection = collection
          @discard_orphans = options[:orphans] == :discard
          @min_level = nil

          if discard_orphans? && !collection.klass.depth_column && ActiveRecord::Base.logger
            ActiveRecord::Base.logger.warn {
              '%s model has no `depth` column, '\
            'it can lead to N+1 queries during #arrange method invocation' % collection.klass
            }
          end

          @cache = Hash.new
          @prepared = false
        end

        def arrange
          prepare unless prepared?

          @arranged ||= collection.each_with_object(Hash.new) do |node, result|
            ancestors = ancestors(node)

            if discard_orphans?
              root = ancestors.first || node

              next if root.level > @min_level
            end

            insertion_point = result

            ancestors.each { |a| insertion_point = (insertion_point[a] ||= {}) }

            insertion_point[node] = {}
          end
        end

        private
        def prepare
          collection.each do |node|
            cache[node.id] = node if node.id
            @min_level = [@min_level, node.level].compact.min
          end

          @prepared = true
        end

        def discard_orphans?
          @discard_orphans
        end

        def prepared?
          @prepared
        end

        # get parent node of +node+
        def parent(node)
          cache[node[node.parent_column]]
        end

        def ancestors(node)
          parent = parent(node)
          parent ? ancestors(parent) + [parent] : []
        end
      end
      private_constant :Arranger
    end
  end
end