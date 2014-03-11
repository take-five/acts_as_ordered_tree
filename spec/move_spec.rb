# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Movement via save', :transactional do
  tree :factory => :default_with_counter_cache do
    root {
      child_1 {
        child_2
        child_3
      }
      child_4 {
        child_5
      }
    }
  end

  def move(node, new_parent, new_position)
    name = "category #{rand(100..1000)}"
    node.parent = new_parent
    node.position = new_position
    node.name = name

    node.save

    expect(node.reload.parent).to eq new_parent
    expect(node.position).to eq new_position
    expect(node.name).to eq name
  end

  context 'when child 2 moved under child 4 to position 1' do
    before { move child_2, child_4, 1 }

    expect_tree_to_match {
      root {
        child_1 :categories_count => 1 do
          child_3 :position => 1
        end
        child_4 :categories_count => 2 do
          child_2 :position => 1
          child_5 :position => 2
        end
      }
    }
  end

  context 'when child 2 moved under child 4 to position 2' do
    before { move child_2, child_4, 2 }

    expect_tree_to_match {
      root {
        child_1 :categories_count => 1 do
          child_3 :position => 1
        end
        child_4 :categories_count => 2 do
          child_5 :position => 1
          child_2 :position => 2
        end
      }
    }
  end

  context 'when level changed' do
    before { move child_1, child_4, 1 }

    expect_tree_to_match {
      root {
        child_4 :categories_count => 2 do
          child_1 :position => 1, :categories_count => 2, :depth => 2 do
            child_2 :position => 1, :depth => 3
            child_3 :position => 2, :depth => 3
          end
          child_5 :position => 2, :depth => 2
        end
      }
    }
  end

  context 'when node moved to root' do
    before { move child_1, nil, 1 }

    expect_tree_to_match {
      child_1 :position => 1, :depth => 0 do
        child_2 :position => 1, :depth => 1
        child_3 :position => 2, :depth => 1
      end
      root :position => 2, :depth => 0 do
        child_4 :depth => 1 do
          child_5 :depth => 2
        end
      end
    }
  end
end