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

World(TreeParserHelper)