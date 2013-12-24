# Acts As Ordered Tree [![Build Status](https://secure.travis-ci.org/take-five/acts_as_ordered_tree.png?branch=master)](http://travis-ci.org/take-five/acts_as_ordered_tree)
WARNING! THIS GEM IS NOT COMPATIBLE WITH <a href="http://ordered-tree.rubyforge.org">ordered_tree gem</a>.

Specify this `acts_as` extension if you want to model an ordered tree structure ([adjacency list hierarchical structure](http://www.sqlsummit.com/AdjacencyList.htm)) by providing a parent association, a children association and a sort column. For proper use you should have a foreign key column, which by default is called `parent_id`, and a sort column, which is by default called `position`.

This extension is mostly compatible with [`awesome_nested_set`](https://github.com/collectiveidea/awesome_nested_set/) gem

## Requirements

Gem is supposed to work with Rails 3.0 and higher including Rails 4.1 beta. We test it with `ruby-1.9.3`, `ruby-2.0.0` and `jruby-1.7.8`. Sorry, support for ruby 1.9.2 and 1.8.7 is dropped. Also, `rubunius` isn't supported since it's quite unstable (I could not even launch rails 3.2 with rbx-2.1.1).

## Features
1. Supports PostgreSQL recursive queries (requires at least `postgresql-8.3`)
2. Holds integrity control via pessimistic database locks. Common situation for `acts_as_list` users is non-unique positions within list. It happens when two concurrent users modify list sumultaneously. `acts_as_ordered_tree` uses pessimistic locks to keep your tree consistent.

## Installation
Install it via rubygems:

```bash
gem install acts_as_ordered_tree
```

## Usage

To make use of `acts_as_ordered_tree`, your model needs to have 2 fields: parent_id and position. You can also have an optional fields: `depth` and `children_count`:
```ruby
class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.integer :company_id
      t.string  :name
      t.integer :parent_id # this is mandatory
      t.integer :position # this is mandatory
      t.integer :depth # this is optional
      t.integer :children_count # this is optional
    end
  end

  def self.down
    drop_table :categories
  end
end
```

Setup your model:

```ruby
class Category < ActiveRecord::Base
  acts_as_ordered_tree

  # gem introduces new ActiveRecord callbacks:
  # *_reorder - fires when position (but not parent node) is changed
  # *_move - fires when parent node is changed
  before_reorder :do_smth
  before_move :do_smth_else
end
```

Now you can use `acts_as_ordered_tree` features:

```ruby
# root
#  \_ child1
#       \_ subchild1
#       \_ subchild2


root = Category.create(:name => "root")
child1 = root.children.create(:name => "child1")
subchild1 = child1.children.create("name" => "subchild1")
subchild2 = child1.children.create("name" => "subchild2")

Category.roots # => [root]

root.root? # => true
root.parent # => nil
root.ancestors # => []
root.descendants # => [child1, subchild1, subchild2]
root.descendants.arrange # => {child1 => {subchild1 => {}, subchild2 => {}}}

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO
1. Fix README typos and grammatical errors (english speaking contributors are welcomed)
2. Add moar examples and docs.
3. Implement converter from other structures (nested_set, closure_tree)