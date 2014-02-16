# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node, '#reload', :transactional do
  shared_examples 'ActsAsOrderedTree::Node#reload' do |model, attrs = {}|
    describe model do
      let(:record) { create model, attrs }
      let(:node) { record.ordered_tree_node }

      # change all attributes
      before { node.parent_id = create(model, attrs).id }
      before { node.position = 3 }
      before { node.depth = 2 if record.ordered_tree.columns.depth? }
      before { record[record.ordered_tree.columns.counter_cache] = 5 if record.ordered_tree.columns.counter_cache? }
      before { record.name = 'another name' }

      it 'reloads attributes related to tree' do
        node.reload

        expect(node.parent_id).to eq nil
        expect(node.position).to eq 1

        if record.ordered_tree.columns.depth?
          expect(node.depth).to eq 0
        end

        if record.class.ordered_tree.columns.counter_cache?
          expect(record.children.size).to eq 0
        end
      end
    end
  end

  include_examples 'ActsAsOrderedTree::Node#reload', :default
  include_examples 'ActsAsOrderedTree::Node#reload', :default_with_counter_cache
end