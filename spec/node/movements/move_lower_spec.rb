# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_lower', :transactional do
  shared_examples '#move_lower' do |factory, attrs = {}|
    describe "#move_lower #{factory}" do
      tree :factory => factory, :attributes => attrs do
        node_1
        node_2
        node_3
      end

      context 'trying to lowest node down' do
        before { node_3.move_lower }

        expect_tree_to_match {
          node_1
          node_2
          node_3
        }
      end

      context 'trying to move node with not lowest position' do
        before { node_2.move_lower }

        expect_tree_to_match {
          node_1
          node_3
          node_2
        }
      end
    end
  end

  include_examples '#move_lower', :default
  include_examples '#move_lower', :default_with_counter_cache
  include_examples '#move_lower', :scoped, :scope_type => 's'
end