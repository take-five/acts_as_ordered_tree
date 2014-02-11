module TestedClassHelper
  def tested_class
    @tested_class || Default
  end

  def tested_class=(class_name)
    @tested_class = class_name.constantize
  end

  def create(attributes)
    @default_attributes ||= {}
    tested_class.create!(@default_attributes.merge(attributes))
  end
end
World(TestedClassHelper)

Given /^tested model is "([^"]+)"$/ do |class_name|
  self.tested_class = class_name
end

Given /^default node attributes are:?$/ do |yaml|
  @default_attributes = YAML.load(yaml).with_indifferent_access
end

Given /^default node attributes are "(.*?)"$/ do |json|
  @default_attributes = JSON.parse(json)
end

module RecordHelper
  def find_node(name)
    tested_class.where(:name => name).first || raise(ActiveRecord::RecordNotFound, "Record with name=#{name} not found")
  end
end
World(RecordHelper)

Then /^I should have following tree:?$/ do |definition|
  definition.should match_actual_tree
end

Then /^I expect tree to be the same$/ do
  @tree.should match_actual_tree
end

When /^I change "([^"]+)" parent to "([^"]+)"(?: with position (\d+))?$/ do |arg1, arg2, arg3|
  @record = find_node(arg1)
  parent = arg2.presence && find_node(arg2)

  @record.parent = parent
  @record.position = arg3
end

When /^I change "([^"]+)" to be root(?: with position (\d+))?$/ do |arg1, position|
  @record = find_node(arg1)
  @record.parent = nil
  @record.position = position
end

When /^I save record$/ do
  expect{@record.save!}.to_not raise_exception
end

Then /^"([^"]+)" should be root$/ do |arg1|
  find_node(arg1).should be_root
end