# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_higher', :transactional do
  shared_examples '#move_higher' do |factory, attrs = {}|
    describe "#move_higher #{factory}" do
      tree :factory => factory, :attributes => attrs do
        node_1
        node_2
        node_3
      end

      context 'trying to move highest node up' do
        before { node_1.move_higher }

        expect_tree_to_match {
          node_1
          node_2
          node_3
        }
      end

      context 'trying to move node with position > 1' do
        before { node_2.move_higher }

        expect_tree_to_match {
          node_2
          node_1
          node_3
        }
      end
    end
  end

  include_examples '#move_higher', :default
  include_examples '#move_higher', :default_with_counter_cache
  include_examples '#move_higher', :scoped, :scope_type => 's'
end