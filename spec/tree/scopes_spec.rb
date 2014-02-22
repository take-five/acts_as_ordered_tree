# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Tree::Scopes, :transactional do
  shared_context 'ActsAsOrderedTree scopes tree' do |model, attrs = {}|
    let!(:root_1) { create model, attrs }
    let!(:child_1) { create model, attrs.merge(:parent => root_1) }
    let!(:grandchild_1) { create model, attrs.merge(:parent => child_1) }
    let!(:root_2) { create model, attrs }
    let!(:child_2) { create model, attrs.merge(:parent => root_2) }
    let!(:grandchild_2) { create model, attrs.merge(:parent => child_2) }

    let(:klass) { root_1.class }
  end

  shared_examples 'ActsAsOrderedTree scopes' do |model, attrs = {}|
    describe model do
      include_context 'ActsAsOrderedTree scopes tree', model, attrs

      describe '.roots' do
        it { expect(klass.roots).to eq [root_1, root_2] }
      end

      describe '.root' do
        it { expect(klass.root).to eq root_1 }
      end
    end
  end

  include_examples 'ActsAsOrderedTree scopes', :default
  include_examples 'ActsAsOrderedTree scopes', :default_with_counter_cache do
    describe '.leaves' do
      include_context 'ActsAsOrderedTree scopes tree', :default_with_counter_cache

      it { expect(DefaultWithCounterCache.leaves.order(:id)).to eq [grandchild_1, grandchild_2] }
      it { expect(root_1.descendants.leaves).to eq [grandchild_1] }
    end
  end
end