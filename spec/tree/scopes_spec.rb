# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Tree::Scopes, :transactional do
  shared_examples 'ActsAsOrderedTree scopes' do |model, attrs = {}|
    describe model.to_s do
      tree :factory => model, :attributes => attrs do
        root_1 {
          child_1 {
            grandchild_1
          }
        }
        root_2 {
          child_2 {
            grandchild_2
          }
        }
      end

      describe '.leaves' do
        it { expect(current_tree.leaves.order(:id)).to eq [grandchild_1, grandchild_2] }
        it { expect(root_1.descendants.leaves).to eq [grandchild_1] }
      end

      describe '.roots' do
        it { expect(current_tree.roots).to eq [root_1, root_2] }
      end

      describe '.root' do
        it { expect(current_tree.root).to eq root_1 }
      end
    end
  end

  include_examples 'ActsAsOrderedTree scopes', :default
  include_examples 'ActsAsOrderedTree scopes', :default_with_counter_cache
  include_examples 'ActsAsOrderedTree scopes', :scoped
end