module ConcurrencyFeaturesHelper
  # Spawn +n+ threads, execute a block and wait for completion
  def concurrently(n)
    n.times.map { |x|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection { yield x }
      end
    }.each(&:join)
  end
end

World(ConcurrencyFeaturesHelper)

When /^I create (\d+) root nodes simultaneously$/ do |size|
  concurrently(size.to_i) do |i|
    tested_class.create!(:name => "root #{i}")
  end
end

When /^I create (\d+) children of "(.*?)" simultaneously$/ do |size, name|
  parent = find_node(name)

  concurrently(size.to_i) do |i|
    tested_class.create!(:name => "child #{i}", :parent => parent)
  end
end

When /^I move nodes "(.*?)" (under|to left of|to right of) "(.*?)" simultaneously$/ do |names, position, target_name|
  target = find_node(target_name)
  nodes = names.split(', ').map { |name| find_node(name) }

  method = case position
             when 'under' then :move_to_child_of
             when 'to left of' then :move_to_left_of
             when 'to right of' then :move_to_right_of
             else raise 'Unknown position'
           end

  concurrently(nodes.size) do |i|
    nodes[i].send(method, target)
  end
end

When /^I move nodes "(.*?)" (to root|higher|lower) simultaneously$/ do |names, position|
  nodes = names.split(', ').map { |name| find_node(name) }

  method = case position
             when 'to root' then :move_to_root
             when 'higher', 'lower' then "move_#{position}"
             else raise 'Unknown position'
           end

  concurrently(nodes.size) do |i|
    nodes[i].send(method)
  end
end

When /^I want to swap nodes "(.*?)" and "(.*?)" to indices (\d+) and (\d+) simultaneously$/ do |arg1, arg2, i1, i2|
  node1, node2  = find_node(arg1), find_node(arg2)
  parent1, parent2 = node1.parent, node2.parent

  pending = Array[
    -> { node1.move_to_child_with_index(parent2, i1.to_i) },
    -> { node2.move_to_child_with_index(parent1, i2.to_i) }
  ]

  concurrently(2) { |i| pending[i].call }
end

Then /^root nodes sorted by "(.*?)" should have "(.*?)" attribute equal to "(.*?)"$/ do |sort_attr, attr, expected|
  tested_class.roots.sort_by(&sort_attr.to_sym).map(&attr.to_sym).should eq JSON.parse(expected)
end

Then /^"(.*?)" children sorted by "(.*?)" should have "(.*?)" attribute equal to "(.*?)"$/ do |parent_name, sort_attr, attr, expected|
  parent = find_node(parent_name)
  parent.children.sort_by(&sort_attr.to_sym).map(&attr.to_sym).should eq JSON.parse(expected)
end