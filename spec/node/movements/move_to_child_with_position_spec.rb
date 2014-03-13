# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_to_child_with_position', :transactional do
  shared_examples '#move_to_child_with_position' do |factory|
    describe "#move_to_child_with_position #{factory}" do
      tree :factory => factory do
        root {
          node_1
          node_2
          node_3 {
            node_4
          }
        }
      end

      context 'moving node to same parent and same position' do
        before { node_2.move_to_child_with_position(root, 2) }

        expect_tree_to_match {
          root {
            node_1
            node_2
            node_3 {
              node_4
            }
          }
        }
      end

      context 'moving node to same parent with another position' do
        before { node_1.move_to_child_with_position(root, 2) }

        expect_tree_to_match {
          root {
            node_2
            node_1
            node_3 {
              node_4
            }
          }
        }
      end

      context 'moving node to same parent to lowest position' do
        before { node_1.move_to_child_with_position(root, 3) }

        expect_tree_to_match {
          root {
            node_2
            node_3 {
              node_4
            }
            node_1
          }
        }
      end

      context 'moving to node to very large position' do
        before { node_4.move_to_child_with_position(root, 100) }

        expect_tree_to_match {
          root {
            node_1
            node_2
            node_3
            node_4
          }
        }
      end

      context 'when attribute, not related to tree, changed' do
        before { @old_name = node_2.name }
        before { node_2.name = 'new name' }

        it { expect{node_2.move_to_child_with_position(root, 2)}.to change(node_2, :name).to(@old_name) }
      end
    end
  end

  include_examples '#move_to_child_with_position', :default
  include_examples '#move_to_child_with_position', :default_with_counter_cache
  include_examples '#move_to_child_with_position', :scoped
end