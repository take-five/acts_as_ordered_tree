Given /^the node "([^"]+)" exists$/ do |name|
  tested_class.create!(:name => name)
end

Given /^the child of "([^"]+)" exists$/ do |name|
  parent = find_node(name)

  tested_class.create!(:name => name, :parent => parent)
end

Given(/^"(.*?)" node has (\d+) children$/) do |parent_name, n|
  step %|"#{parent_name}" node has #{n} children with prefix "node"|
end

Given(/^"(.*?)" node has (\d+) children with prefix "(.*?)"$/) do |parent_name, n, prefix|
  parent = find_node(parent_name)

  n.to_i.times do |i|
    name = "#{prefix} #{i + 1}"

    tested_class.create!(:name => name, :parent => parent)
  end
end

Given /^the following tree exists:?$/ do |definition|
  sequence = 0

  parse_tree_definition(definition) do |node|
    parent = node.parent && find_node(node.parent)
    name = node.name == '*' ? "node #{sequence += 1}" : node.name
    tested_class.create!(:name => name, :parent => parent)
  end
end