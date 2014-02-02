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
  definition.should match_actual_tree
end

When /^I change "([^"]+)" parent to "([^"]+)"$/ do |arg1, arg2|
  @record = find_node(arg1)
  parent = arg2.presence && find_node(arg2)

  @record.parent = parent
end

When /^I change "([^"]+)" to be root$/ do |arg1|
  @record = find_node(arg1)
  @record.parent = nil
end

When /^I save record$/ do
  expect{@record.save!}.to_not raise_exception
end

Then /^"([^"]+)" should be root$/ do |arg1|
  find_node(arg1).should be_root
end