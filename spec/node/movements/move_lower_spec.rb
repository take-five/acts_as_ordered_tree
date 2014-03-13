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

      context 'when attribute, not related to tree changed' do
        before { @old_name = node_2.name }
        before { node_2.name = 'new name' }

        it { expect{node_2.move_lower}.to change(node_2, :name).to(@old_name) }
      end
    end
  end

  include_examples '#move_lower', :default
  include_examples '#move_lower', :default_with_counter_cache
  include_examples '#move_lower', :scoped, :scope_type => 's'
end