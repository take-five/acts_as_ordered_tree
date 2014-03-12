# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_to_root', :transactional do
  shared_examples '#move_to_root' do |factory, attrs = {}|
    describe "#move_to_root #{factory}" do
      tree :factory => factory, :attributes => attrs do
        root_1 {
          node_1
          node_2
          node_3 {
            node_4
          }
        }
        root_2 {
          node_5
        }
      end

      context 'moving root node to root' do
        before { root_2.move_to_root }

        expect_tree_to_match {
          root_1 {
            node_1
            node_2
            node_3 {
              node_4
            }
          }
          root_2 {
            node_5
          }
        }
      end

      context 'moving inner node to root' do
        before { node_3.move_to_root }

        expect_tree_to_match {
          root_1 {
            node_1
            node_2
          }
          root_2 {
            node_5
          }
          node_3 {
            node_4
          }
        }
      end
    end
  end

  include_examples '#move_to_root', :default
  include_examples '#move_to_root', :default_with_counter_cache
  include_examples '#move_to_root', :scoped, :scope_type => 's'
end