# Acts As Ordered Tree
WARNING! THIS GEM IS NOT COMPATIBLE WITH <a href="http://ordered-tree.rubyforge.org">ordered_tree gem</a>.

Specify this `acts_as` extension if you want to model an ordered tree structure by providing a parent association, a children
association and a sort column. For proper use you should have a foreign key column, which by default is called `parent_id`, and
a sort column, which by default is called `position`.

## Requirements
Gem depends on `active_record >= 3`.

## Installation
Install it via rubygems:
```bash
  gem install acts_as_ordered_tree
```

Gem depends on `acts_as_tree` and `acts_as_list` gems.

Setup your model:
```ruby
  class Node < ActiveRecord::Base
    acts_as_ordered_tree

    # gem introduces new ActiveRecord callbacks:
    # *_reorder - fires when position (but not parent node) is changed
    # *_move - fires when parent node is changed
    before_reorder :do_smth
    before_move :do_smth_else
  end
```

## Example
```ruby
  root
   \_ child1
        \_ subchild1
        \_ subchild2


  root = Node.create(:name => "root")
  child1 = root.children.create(:name => "child1")
  subchild1 = child1.children.create("name" => "subchild1")
  subchild2 = child1.children.create("name" => "subchild2")

  Node.roots # => [root]

  root.root? # => true
  root.parent # => nil
  root.ancestors # => []
  root.descendants # => [child1, subchild1, subchild2]

  child1.parent # => root
  child1.ancestors # => [root]
  child1.children # => [subchild1, subchild2]
  child1.descendants # => [subchild1, subchild2]
  child1.root? # => false
  child1.leaf? # => false

  subchild1.ancestors # => [child1, root]
  subchild1.root # => [root]
  subchild1.leaf? # => true
  subchild1.first? # => true
  subchild1.last? # => false
  subchild2.last? # => true

  subchild1.move_to_above_of(child1)
  subchild1.move_to_bottom_of(child1)
  subchild1.move_to_child_of(root)
  subchild1.move_lower
  subchild1.move_higher
```