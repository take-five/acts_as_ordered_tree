# coding: utf-8

module ActsAsOrderedTree
  module Relation
    # AAOT::Relation::Recursive adds ability to create self-joined recursive relations.
    #
    # First, you have to specify how relation should reference to itself and starting conditions.
    #
    # @example Traverse descendants of all root node
    #   MyModel.connect_by(:id => :parent_id).start_with { |s| s.where(:parent_id => nil) }
    #
    # It says: "Start recursive iteration with nodes which have parent_id=NULL and traverse
    # into deep by finding nodes which have `parent_id` attribute equal to current node's
    # `id` attribute"
    #
    # @example Traverse all ancestors of node with ID=1
    #   MyModel.connect_by(:parent_id => :id).start_with { |s| s.where(:id => 1) }
    #
    # Second, you may specify conditions and orderings to apply to iteration term of recursive query
    # by calling #with_recursive method.
    #
    # @example Traverse descendants down to 4th level
    #   MyModel.connect_by(:id => :parent_id)
    #          .with_recursive { |d| d.where('depth < 5') }
    #          .start_with { |s| s.where(:id => 1) }
    #
    # You can access non-recursive term by sending #previous method to value yielded to block.
    #
    # @example Traverse descendants, but visit only those whose parent has depth < 3
    #   MyModel.connect_by(:id => :parent_id)
    #          .start_with { |s| s.select(:depth).where(:id => 1) }
    #          .with_recursive { |d| d.where(d.previous[:depth].lt 3) }
    module Recursive
      # Specify start conditions of recursive term. If you think of tree as
      # acyclic graph, specify vertexes from which depth-first traversal will
      # start.
      #
      # @example
      #   MyModel.connect_by(:id => :parent_id)
      #          .start_with { |roots| roots.where(:id => 1) }
      #
      # @example
      #   MyModel.connect_by(:id => :parent_id).
      #          .start_with(MyModel.where(:id => 1))
      def start_with(scope = nil, &block)
        with_recursive do |relation|
          relation.start_with(scope, &block)
        end

        self
      end

      # Specify keys, which will be used to join recursive and non-recursive term
      # of WITH RECURSIVE part of query.
      #
      # @param [Hash] keys a hash containing {original_term_key => recursive_term_key} map
      #
      # @example Traverse descendants
      #   MyModel.connect_by(:id => :parent_id)
      #
      # @example Traverse ancestors with same `type` column as start node
      #   MyModel.connect_by(:parent_id => :id, :type => :type)
      def connect_by(keys)
        with_recursive do |relation|
          relation.connect_by(keys)
        end

        self
      end

      # Specify recursive term conditions for recursive query.
      #
      # @example
      #   MyModel.with_recursive do |descendants|
      #     descendants.where('position < ?', 4)
      #   end.
      #   connect_by(:id => :parent_id).
      #   start_with(MyModel.where(:parent_id => nil))
      def with_recursive
        self.recursive_join_value ||= RecursiveRelation.new(klass, table)
        self.recursive_join_value = yield recursive_join_value if block_given?
        self
      end

      # @api private
      def recursive_join_value
        @values ? @values[:recursive_join] : @recursive_join_value
      end

      # @api private
      def recursive_join_value=(value)
        @values ? @values[:recursive_join] = value : @recursive_join_value = value
      end

      Compatibility.version '< 4.1.0' do
        # AR::Relation#arel calls `with_default_scope.build_arel` which
        # does not respect ours `recursive_join_value`
        #
        # @api private
        def with_default_scope
          relation = super
          relation.recursive_join_value = recursive_join_value
          relation
        end
      end

      # Here we override original method, because update with join to recursive CTE
      # is too tricky, so we perform update_all on empty relation:
      # `update xxx set ... where id in (select id from xxx join (with recursive ...) ...)`
      def update_all(*args)
        if recursive_join_value
          with_subquery.update_all(*args)
        else
          super
        end
      end

      # @api private
      def build_arel
        if recursive_join_value
          as = recursive_join_value.arel.as("#{table.name}__recursive")
          super.join(as).on(as[klass.primary_key].eq(table[klass.primary_key]))
        else
          super
        end
      end

      private
      def with_subquery
        subquery = select(table[klass.primary_key])
        subquery.order_values = []
        subquery.limit_value = nil

        ActiveRecord::Relation.new(klass, table).where(klass.primary_key => subquery)
      end

      # @todo beautify, refactor, write docs and move it to separate library
      class RecursiveRelation < ActiveRecord::Relation
        attr_reader :start_with_value

        def initialize(*)
          super

          @connect_keys = []
          @start_with_value = klass.default_scoped
        end

        # @param [Hash] join_keys a hash containing {original_term_key => recursive_term_key} map
        def connect_by(join_keys)
          @connect_keys = join_keys.map { |original_key, recursive_key| [original_key.to_s, recursive_key.to_s] }

          self
        end

        def start_with(scope = nil)
          @start_with_value = scope if scope
          @start_with_value = yield @start_with_value if block_given?

          self
        end

        # Returns Arel::Table object that represents recursive CTE.
        def recursive_table
          @recursive_table ||= Arel::Table.new("#{table.name}__recursive")
        end
        alias_method :previous, :recursive_table

        def build_arel
          raise 'Incomplete recursive relation. You MUST specify CONNECT BY clause' if @connect_keys.empty?

          self.select_values += columns

          recursive_term = super.
            join(previous).
            on(recursive_join_conditions)

          union = original_term.union(:all, recursive_term)

          as_stmt = Arel::Nodes::As.new(recursive_table, union)

          Arel::SelectManager.new(Arel::Table.engine).
            with(:recursive, as_stmt).
            from(recursive_table).
            project(recursive_table[Arel.star])
        end

        private
        def original_term
          # ORDER, LIMIT and OFFSET aren't allowed in non-recursive part of recursive query
          @start_with_value.
              select(columns).
              except(:order, :limit, :offset).arel
        end

        private
        def recursive_join_conditions
          @connect_keys.map do |original_key, recursive_key|
            table[recursive_key].eq(recursive_table[original_key])
          end.reduce(:and)
        end

        # Columns to select in both terms
        def columns
          columns = [table[klass.primary_key]] + @connect_keys.flatten.map { |key| table[key] }
          columns.uniq
        end
      end
      private_constant :RecursiveRelation
    end # module Recursive
  end # module Relation
end # module ActsAsOrderedTree