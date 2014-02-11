# coding: utf-8

module TreeDefinition
  class Parser
    class Error < StandardError; end

    def self.parse(input)
      new.parse(input)
    end

    def parse(input)
      initial_indent = input.lines.first.match(/\A\s*/).to_s.length

      # remove initial indent from every line
      input.gsub!(/^\s{#{initial_indent}/, '')

      root = Nodes::Root.new
      stack = [root]
      level = 0
      last = root

      input.lines.each do |line|
        indent = line.match(/\A\s*/).to_s.length
        node_level = indent / 2

        if node_level > level
          raise Error, 'Wrong indentation in line "%s"' % line if node_level - level > 1

          stack << last
        elsif node_level < level
          diff = level - node_level
          raise Error, 'Wrong indentation in line "%s"' % line if diff > stack.size

          diff.times { stack.pop }
        end

        parent = stack.last

        last = parse_line(line)
        parent.children << last

        level = node_level
      end

      root
    end

    private
    def parse_line(line)
      line = line.chomp.gsub(/\A\s+/, '')
      parts = line.split('/').map(&:strip)

      node = Nodes::Node.new

      # 1st part is a name
      name = parts.shift
      node.name = name == '*' ? Nodes::Any.new : Nodes::Name.new(name)

      # other parts is attributes
      parts.each do |part|
        k, v = part.split('=').map(&:strip)

        attr = Nodes::Attribute.new
        attr.name = k
        attr.value = v == '*' ? Nodes::Any.new : Nodes::Value.new(v)

        node.attributes << attr
      end

      node
    end
  end
end

p TreeDefinition::Parser.parse <<-INPUT
  root
    child 1 / position = 1
    child 2 / position = 2
      child 3
      * / position = 2
INPUT