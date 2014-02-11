# coding: utf-8

When /^I move node "(.+?)" (to root|higher|lower)$/ do |name, position|
  node = find_node(name)

  method = case position
             when 'to root' then :move_to_root
             when 'higher', 'lower' then "move_#{position}"
             else raise 'Unknown position'
           end

  node.send(method)
end

When /^I move node "(.+?)" (under|to left of|to right of|to child of) (?:"(.+?)"|Nothing)$/ do |name, position, target_name|
  node = find_node(name)
  target = target_name && find_node(target_name)

  method = case position
             when 'under', 'to child of' then :move_to_child_of
             when 'to left of' then :move_to_left_of
             when 'to right of' then :move_to_right_of
             else raise 'Unknown position'
           end

  node.send(method, target)
end

When /^I move node "(.+?)" (?:under|to child of) (?:"(.+?)"|Nothing) to (position|index) (-?\d+)$/ do |name, target_name, kind, value|
  node = find_node(name)
  target = target_name && find_node(target_name)
  method = "move_to_child_with_#{kind}"
  node.send(method, target, value)
end