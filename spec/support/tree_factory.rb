require 'set'

# @example
#   describe Something do
#     tree :factory => :my_model_factory, :attributes => {:scope_type => 'xxx'} do
#       root {
#         child_1
#         child_2 {
#           child_3 :name => 'a child'
#         }
#       }
#     end
#
#     it 'should have root' do
#       expect(root).to have(2).children
#     end
#
#     it 'should move node' do
#       child_2.move_higher
#       expect(current_tree).to match_tree ->{
#         root {
#           child_2, :position => 1 do
#             child_3 :name => 'a child'
#           end
#           child_1, :position => 2
#         }
#       }
#     end
#   end
module TreeFactory
  module AbstractNode
    attr_reader :parent
    attr_accessor :position

    def children
      @children ||= []
    end

    def descendants
      children.map { |child| [child] + child.descendants }.flatten
    end

    def self_and_descendants
      [self] + descendants
    end

    def parent=(value)
      @parent = value

      if @parent
        @parent.children << self
      end
    end

    def ancestors
      parent ? parent.ancestors + [parent] : []
    end

    def level
      ancestors.size
    end

    def indentation
      ' ' * 2 * level
    end

    def inspect_attributes
      attributes.map do |k, v|
        " / #{k} = #{v}"
      end.join
    end

    def inspect_children
      result = String.new

      if children.any?
        result << "\n"
        result << children.map(&:inspect).join("\n")
      end

      result
    end

    def matches?(record)
      record &&
          record.level == level &&
          record.ordered_tree_node.position == position &&
          attributes_matches?(record) &&
          record.children.size == children.size &&
          children.zip(record.children).all? { |n, r| n.matches?(r) }
    end

    def attributes_matches?(record)
      attributes.all? do |attr, value|
        if attr.is_a?(Symbol)
          record.__send__(attr)
        else
          record.instance_eval(attr)
        end == value
      end
    end
  end

  class Node < Struct.new(:name, :attributes)
    include AbstractNode

    attr_accessor :context

    def inspect
      if context
        result = indentation
        result << record_name
        result << " / id = #{as_record.id}"
        result << inspect_attributes
        result << inspect_children
        result
      else
        super
      end
    end

    def matches?(record)
      record && record == as_record && super
    end

    private
    def as_record
      @record ||= context.__send__(name)
    end

    def record_name
      to_s = [:name, :to_str, :to_s].detect { |m| as_record.respond_to?(m) }
      as_record.__send__(to_s)
    end
  end

  class AnyNode < Struct.new(:attributes)
    include AbstractNode

    def inspect
      result = indentation
      result << '*'
      result << inspect_attributes
      result << inspect_children
      result
    end
  end

  class Parser
    attr_reader :ast

    def initialize(options = {})
      @attributes = options.fetch(:attributes, {})
      @parent = nil
    end

    def parse(context, &tree)
      @ast = []
      @context = context
      instance_exec(&tree)
      ast
    end

    private
    def with_parent(parent_node, &block)
      old, @parent = @parent, parent_node
      instance_exec(&block) if block_given?
    ensure
      @parent = old
    end

    def node(name, attributes = {}, &block)
      build_node(block) do
        Node.new(name.to_sym, @attributes.merge(attributes))
            .tap { |x| x.context = @context }
      end
    end

    def any(attributes = {}, &block)
      build_node(block) { AnyNode.new(@attributes.merge(attributes)) }
    end

    def method_missing(name, attributes = {}, &block)
      node(name, attributes, &block)
    end

    def build_node(children_block)
      node = yield

      node.parent = @parent

      if node.parent
        node.position = node.parent.children.size
      else
        @ast << node
        node.position = @ast.size
      end

      with_parent(node, &children_block)
    end
  end

  class Builder
    attr_reader :factory

    def initialize(test_suite, options)
      @parser = Parser.new(options)
      @suite = test_suite
      @factory = options.fetch(:factory, @suite.described_class.name.underscore)
    end

    def build(&tree)
      memoize_nodes_class

      ast = @parser.parse(@suite, &tree)
      ast.each { |o| build_node(o) }
    end

    private
    def build_node(node)
      factory = @factory

      raise 'Cannot build ANY node in BEFORE section' if node.is_a?(AnyNode)

      @suite.let!(node.name) do
        parent = node.parent && send(node.parent.name)

        create factory, node.attributes.merge(:parent => parent)
      end

      node.children.each { |o| build_node(o) }
    end

    def memoize_nodes_class
      factory = FactoryGirl.factory_by_name(@factory)
      @suite.let(:current_tree) { factory.build_class }
    end
  end

  # Class level helper
  def tree(options, &block)
    Builder.new(self, options).build(&block)
  end

  def expect_tree_to_match(&block)
    caller = caller(1).first
    file, line, * = caller.split(':')
    location = [file, line].join(':')
    example = it { expect(current_tree).to match_tree(block) }
    example.metadata[:location] = location
    example.metadata[:file_path] = file
  end
end

RSpec::Matchers.define :match_tree do |tree|
  match do |tree_klass|
    @expected_tree = tree
    @klass = tree_klass

    ast.zip(@klass.roots).all? { |node, record| node.matches?(record) }
  end

  failure_message_for_should do |tree_klass|
    message = "expected actual tree\n\n"
    message << inspect_actual_tree(tree_klass)
    message << "\nto match\n\n"
    message << ast.map(&:inspect).join("\n")
  end

  def ast
    @ast ||= TreeFactory::Parser.new.parse(matcher_execution_context, &@expected_tree)
  end

  def attributes_to_expose
    @attributes_to_expose ||= flatten_ast.each_with_object(Set[:id]) do |node, attrs|
      attrs.merge(node.attributes.keys)
    end.to_a
  end

  def flatten_ast
    ast.map(&:self_and_descendants).flatten
  end

  def inspect_actual_tree(tree_klass)
    result = String.new

    tree_klass.roots.each do |root|
      root.self_and_descendants.each do |record|
        result << "#{inspect_record(record)}\n"
      end
    end

    result
  end

  def inspect_record(record)
    result = String.new
    result << indentation(record.level)
    result << record_name(record)

    attributes_to_expose.each do |attr|
      result << " / #{attr} = #{record.send(attr)}"
    end
    result
  end

  def record_name(record)
    to_s = [:name, :to_str, :to_s].detect { |m| record.respond_to?(m) }
    record.send(to_s)
  end

  def indentation(level)
    ' ' * level * 2
  end
end