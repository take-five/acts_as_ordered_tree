# debug step
Then /^I should see whole tree$/ do
  ptree = ->(node = nil) {
    node ||= tested_class.root

    puts ('  ' * node.level) + node.name + " / d=#{node.level}, p=#{node[node.position_column]}"
    node.children.each { |c| ptree[c] }
  }

  ptree.call
end