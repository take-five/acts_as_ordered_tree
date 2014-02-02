module TreeParserHelper
  class TreeNode
    attr_accessor :name, :parent

    def initialize(name, parent)
      @name, @parent = name, parent
    end

    def ==(other)
      name_matches?(other) &&
          parent == other.parent &&
          attributes_match?(other)
    end
    alias_method :eql?, :==

    def inspect
      str = "#{parent || 'nil'} -> #{name}"
      str << ' / ' if attributes.any?
      str << attributes.map { |k, v| "#{k} = #{v}" }.join(' / ')
      str
    end

    def attributes
      @attributes ||= {}.with_indifferent_access
    end

    private
    def attributes_match?(other)
      attributes.each { |k, v| return false if other.attributes[k].to_s != v.to_s }
      true
    end

    def name_matches?(other)
      name == '*' || other.name == '*' || name == other.name
    end
  end

  def parse_tree_definition(definition)
    initial_indent = definition.lines.first.match(/\A\s*/).to_s.length

    # remove initial indent from every line
    definition.gsub!(/^\s{#{initial_indent}/, '')

    stack = []
    level = 0
    last = nil

    definition.lines.each do |line|
      indent = line.match(/\A\s*/).to_s.length
      node_level = indent / 2

      if node_level > level
        raise 'Wrong indentation in line "%s"' % line if node_level - level > 1

        stack << last
      elsif node_level < level
        diff = level - node_level
        raise 'Wrong indentation in line "%s"' % line if diff > stack.size

        diff.times { stack.pop }
      end

      parent = stack.last
      #last = TreeNode.new(line.chomp.gsub(/\A\s+/, ''), parent.try(:name))
      last = create_tree_node_from_line(line, parent.try(:name))
      level = node_level

      yield last
    end
  end

  def print_tree
    puts inspect_tree
  end

  def inspect_tree(node = nil, buf = '')
    if node
      buf << ('  ' * node.level) + node.name + " / level = #{node.level} / position = #{node[node.position_column]}"

      node.attributes.except(
          node.class.primary_key,
          'name',
          node.depth_column.to_s,
          node.position_column.to_s,
          node.parent_column.to_s
      ).each do |k, v|
        buf << " / #{k} = #{v.inspect}"
      end

      buf << "\n"

      node.children.each { |c| inspect_tree(c, buf) }
    else
      tested_class.roots.each { |root| inspect_tree(root, buf) }
    end

    buf
  end

  private
  def create_tree_node_from_line(line, parent)
    line = line.chomp.gsub(/\A\s+/, '')
    parts = line.split('/').map(&:strip)

    # 1st part is a name
    node = TreeNode.new(parts.shift, parent)

    # other parts is attributes
    parts.each do |part|
      k, v = part.split('=').map(&:strip)
      node.attributes[k] = v
    end

    node
  end
end

RSpec::Matchers.define :match_actual_tree do
  match do |definition|
    expected_tree(definition) == actual_tree
  end

  failure_message_for_should do |definition|
    "expected that \n\n#{inspect_tree}\n\nwould match\n\n#{definition}\n\n"
  end

  def actual_tree
    tested_class.roots.map do |root|
      root.self_and_descendants.map do |node|
        tnode = TreeParserHelper::TreeNode.new(node.name, node.parent.try(:name))
        tnode.attributes[:level] = node.level
        tnode.attributes[:position] = node[node.position_column]
        tnode.attributes.merge!(node.attributes)
        tnode
      end
    end.reduce(:+)
  end

  def expected_tree(definition)
    expected_tree = []
    parse_tree_definition(definition) { |node| expected_tree << node }
    expected_tree
  end
end

World(TreeParserHelper)