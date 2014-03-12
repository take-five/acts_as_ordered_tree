# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_to_right_of', :transactional do
  shared_examples '#move_to_right_of' do |factory|
    describe "#move_to_right_of #{factory}" do
      tree :factory => factory do
        root {
          node_1
          node_2
          node_3 {
            node_4
          }
        }
      end

      context 'moving node to same parent higher' do
        before { node_3.move_to_right_of(node_1) }

        expect_tree_to_match {
          root {
            node_1
            node_3 {
              node_4
            }
            node_2
          }
        }
      end

      context 'moving node to next position' do
        before { node_1.move_to_right_of(node_2) }

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

      context 'moving node to same parent lower' do
        before { node_1.move_to_right_of(node_3) }

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

      context 'moving inner node to right of root node' do
        before { node_3.move_to_right_of(root) }

        expect_tree_to_match {
          root {
            node_1
            node_2
          }
          node_3 {
            node_4
          }
        }
      end

      context 'moving inner node to right of another inner node (shallower)' do
        before { node_4.move_to_right_of(node_1) }

        expect_tree_to_match {
          root {
            node_1
            node_4
            node_2
            node_3
          }
        }
      end

      context 'moving inner node to right of another inner node (deeper)' do
        before { node_1.move_to_right_of(node_4) }

        expect_tree_to_match {
          root {
            node_2
            node_3 {
              node_4
              node_1
            }
          }
        }
      end

      context 'Attempt to perform impossible movement' do
        it { expect{ root.move_to_right_of(node_1) }.not_to change(current_tree, :all) }
        it { expect{ node_3.move_to_right_of(node_4) }.not_to change(current_tree, :all) }
        it { expect{ node_1.move_to_right_of(node_1) }.not_to change(current_tree, :all) }
        it { expect{ node_3.move_to_right_of(node_3) }.not_to change(current_tree, :all) }
      end
    end
  end

  include_examples '#move_to_right_of', :default
  include_examples '#move_to_right_of', :default_with_counter_cache
  include_examples '#move_to_right_of', :scoped, :scope_type => 's'
end