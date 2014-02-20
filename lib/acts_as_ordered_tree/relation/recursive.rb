# coding: utf-8

module ActsAsOrderedTree
  module Relation
    # AAOT::Relation::Recursive adds ability to create self-joined recursive relations.
    #
    # First, you have to specify how relation should reference to itself.
    #
    # @example Traverse descendants
    #   MyModel.where(:id => 1).recursive_join(:id => :parent_id)
    #
    # @example Traverse ancestors
    #   MyModel.where(:id => 1).recursive_join(:parent_id => :id)
    #
    # Second, you may specify conditions and orderings to apply to iteration term of recursive query.
    # That's the way how you can stop traversing tree.
    #
    # @example Traverse descendants down to 4th level
    #   MyModel.where(:id => 1).recursive_join(:id => :parent_id) { |d| d.where('depth < 5') }
    #
    # There are is one more way to do exactly the same. By calling #recursive method on scope,
    # you can modify traverse conditions:
    #
    # @example Traverse descendants down to 4th level
    #   MyModel.where(:id => 1).recursive_join(:id => :parent_id).recursive { |d| d.where('depth < 5') }
    #
    # You can access non-recursive term by sending #previous method to value yielded to block.
    #
    # @example Traverse descendants, but visit only those whose parent has depth < 3
    #   MyModel.where(:id => 1).
    #     recursive_join(:id => :parent_id).
    #     start_with { |s| s.select(:depth) }.
    #     recursive { |d| d.where(d.previous[:depth].lt 3) }
    #
    # Also you can change non-recursive term of recursive query by changing start conditions:
    #
    # @example
    #   MyModel.where(:id => 1).recursive_join(:id => :parent_id).start_with { |s| s.where(:archived => false) }
    #   # start conditions are: where(:id => 1, :archived => false)
    module Recursive
      # Create recursive JOIN to self
      #
      # @example
      #   # descendants query
      #   MyModel.unscoped.recursive_join(:id => :parent_id) do |descendants|
      #     descendants.where('position < ?', 4)
      #   end
      #
      #   # ancestors query
      #   MyModel.unscoped.recursive_join(:parent_id => :id)
      #
      # @param [Hash] join_keys a hash explaining how original (starting) term will join to recursive term,
      #   i.e. `{:id => :parent_id}` means that `id` key from starting term will be joined to `parent_id` key
      #   from recursive term (descendants query).
      def recursive_join(join_keys, &block)
        relation = respond_to?(:spawn) ? spawn : clone
        relation.recursive_join!(join_keys, &block)
      end

      # Transforms current relation to recursively joined to self
      #
      # @example
      #   MyModel.unscoped.recursive_join!(:id => :parent_id).start_with { |x| x.where(:parent_id => nil) }
      def recursive_join!(join_keys, &block)
        relation = RecursiveRelation.new(klass, table, join_keys)

        self.recursive_join_value = relation.start_with(self)

        recursive(&block)

        self.where_values = default_scope_values
        self.limit_value = nil
        self.offset_value = nil

        self
      end

      # Modify original term via block
      #
      # @example
      #   MyModel.unscoped.recursive_join(:id => :parent_id) do |descendants|
      #     descendants.where('position < ?', 4).start_with { |roots| roots.where(:id => 1) }
      #   end
      #
      #   # is equivalent to
      #
      #   MyModel.unscoped.recursive_join(:id => :parent_id) do |descendants|
      #     descendants.where('position < ?', 4)
      #   end.start_with { |roots| roots.where(:id => 1) }
      def start_with(&block)
        return self unless recursive_join_value

        recursive_join_value.start_with(&block)

        self
      end

      # Modify recursive term via block
      #
      # @example
      #   MyModel.unscoped.recursive_join(:id, :parent_id).recursive do |descendants|
      #     descendants.where('position < ?', 4)
      #   end
      def recursive
        return self unless recursive_join_value

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
        # @api private
        def with_default_scope
          relation = super
          relation.recursive_join_value = recursive_join_value
          relation
        end

        def default_scope_values
          []
        end
      end

      Compatibility.version '>= 4.1.0' do
        def default_scope_values
          klass.default_scoped.where_values
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

        # @param [Class] klass
        # @param [Arel::Table] table
        # @param [Hash] join_keys a hash containing {original_term_key => recursive_term_key} map
        def initialize(klass, table, join_keys)
          super(klass, table)

          @join_keys = join_keys.map { |original_key, recursive_key| [original_key.to_s, recursive_key.to_s] }
        end

        def start_with(scope = nil)
          if scope
            @start_with_value = scope.select(columns)

            self.select_values = start_with_value.select_values.clone
          end

          @start_with_value = yield @start_with_value if block_given?

          self
        end

        # Returns Arel::Table object that represents recursive CTE.
        def recursive_table
          @recursive_table ||= Arel::Table.new("#{table.name}__recursive")
        end
        alias_method :previous, :recursive_table

        def build_arel
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
          @start_with_value.except(:order, :limit, :offset).arel
        end

        private
        def recursive_join_conditions
          @join_keys.map do |original_key, recursive_key|
            table[recursive_key].eq(recursive_table[original_key])
          end.reduce(:and)
        end

        # Columns to select in both terms
        def columns
          columns = [table[klass.primary_key]] + @join_keys.flatten.map { |key| table[key] }
          columns.uniq
        end
      end
      private_constant :RecursiveRelation
    end # module Recursive
  end # module Relation
end # module ActsAsOrderedTree