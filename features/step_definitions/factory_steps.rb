# coding: utf-8

require 'securerandom'

When /^I create root node "(.+?)"$/ do |name|
  create(:name => name)
end

When /^I create root node$/ do
  name = "root #{SecureRandom.hex(2)}"
  step %|I create root node "#{name}"|
end

When /^I create node "(.+?)" under "(.+?)"$/ do |name, target|
  parent = find_node(target)

  create(:name => name, :parent => parent)
end

When /^I create node under "(.+?)"$/ do |target|
  name = "node #{SecureRandom.hex(2)}"
  step %|I create node "#{name}" under "#{target}"|
end

Given /^the following tree exists:?$/ do |definition|
  sequence = 0

  parse_tree_definition(definition) do |node|
    parent = node.parent && find_node(node.parent)
    name = node.name == '*' ? "node #{sequence += 1}" : node.name
    create(:name => name, :parent => parent)
  end

  @tree = definition
end
