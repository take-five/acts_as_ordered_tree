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
  class Node < Struct.new(:name, :attributes)
    attr_reader :parent

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
  end

  class Parser
    attr_reader :ast

    def initialize(options = {})
      @attributes = options.fetch(:attributes, {})
      @parent = nil
      @ast = []
    end

    def parse(&tree)
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
      node = Node.new(name.to_sym, attributes)
      node.parent = @parent

      @ast << node unless @parent

      with_parent(node, &block)
    end

    def method_missing(name, attributes = {}, &block)
      node(name, attributes, &block)
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

      ast = @parser.parse(&tree)
      ast.each { |o| build_node(o) }
    end

    private
    def build_node(node)
      factory = @factory

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

    ast.zip(@klass.roots).all? { |node, record| node_equals_to_record?(node, record) }
  end

  failure_message_for_should do |tree_klass|
    message = "expected actual tree\n\n"
    message << inspect_actual_tree(tree_klass)
    message << "\nto match\n\n"
    message << inspect_expected_tree
  end

  def ast
    @ast ||= TreeFactory::Parser.new.parse(&@expected_tree)
  end

  def node_equals_to_record?(node, record)
    if node && record
      node_record = matcher_execution_context.__send__(node.name).reload
      result = node_record == record
      result &&= node_record.parent == record.parent
      result &&= node_record.level == record.level
      result &&= node.attributes.all? { |attr, value| record.send(attr) == value }
      result && node.children.zip(record.children).all? { |n, r| node_equals_to_record?(n, r) }
    end
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

  def inspect_expected_tree
    ast.map { |node| inspect_node(node) }.join("\n")
  end

  def inspect_node(node, level = 0)
    result = String.new
    result << indentation(level)

    record = matcher_execution_context.__send__(node.name)
    result << record_name(record)
    result << " / id = #{record.id}"

    node.attributes.each do |k, v|
      result << " / #{k} = #{v}"
    end

    if node.children.any?
      result << "\n"
      result << node.children.map { |x| inspect_node(x, level + 1) }.join("\n")
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