module TestedClassHelper
  def tested_class
    @tested_class || Default
  end

  def tested_class=(class_name)
    @tested_class = class_name.constantize
  end
end
World(TestedClassHelper)

Given /^tested model is "([^"]+)"$/ do |class_name|
  self.tested_class = class_name
end

module RecordHelper
  def find_node(name)
    tested_class.where(:name => name).first || raise(ActiveRecord::RecordNotFound, "Record with name=#{name} not found")
  end
end
World(RecordHelper)

Then /^I should have following tree:?$/ do |definition|
  current_tree = tested_class.roots.map do |root|
    root.self_and_descendants.map do |node|
      tnode = TreeParserHelper::TreeNode.new(node.name, node.parent.try(:name))
      tnode.attributes[:level] = node.level
      tnode.attributes[:position] = node[node.position_column]
      tnode
    end
  end.reduce(:+)

  expected_tree = []
  parse_tree_definition(definition) { |node| expected_tree << node }

  expected_tree.should eq current_tree
end