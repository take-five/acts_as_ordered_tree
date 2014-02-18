# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Traversals do
  shared_examples 'ActsAsOrderedTree::Node traversals' do |model, attrs = {}|
    describe '#root' do
      let!(:root_1) { create model, attrs }
      let(:child_1) { create model, attrs.merge(:parent => root_1) }
      let(:grandchild_1) { create model, attrs.merge(:parent => child_1) }
      let!(:root_2) { create model, attrs }
      let(:child_2) { create model, attrs.merge(:parent => root_2) }
      let(:grandchild_2) { create model, attrs.merge(:parent => child_2) }

      it { expect(root_1.root).to eq root_1 }
      it { expect{root_1.root}.not_to query_database }
      it { expect(child_1.root).to eq root_1 }
      it { expect(grandchild_1.root).to eq root_1 }

      it { expect(root_2.root).to eq root_2 }
      it { expect{root_2.root}.not_to query_database }
      it { expect(child_2.root).to eq root_2 }
      it { expect(grandchild_2.root).to eq root_2 }
    end
  end

  include_examples 'ActsAsOrderedTree::Node traversals', :default
  include_examples 'ActsAsOrderedTree::Node traversals', :default_with_counter_cache
  include_examples 'ActsAsOrderedTree::Node traversals', :scoped, :scope_type => 'a'
end