# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Traversals, :transactional do
  shared_examples 'ActsAsOrderedTree::Node traversals' do |model, attrs = {}|
    let(:root_1) { create model, attrs }
    let(:child_1) { create model, attrs.merge(:parent => root_1) }
    let(:grandchild_1) { create model, attrs.merge(:parent => child_1) }
    let(:root_2) { create model, attrs }
    let(:child_2) { create model, attrs.merge(:parent => root_2) }
    let(:grandchild_2) { create model, attrs.merge(:parent => child_2) }

    before { [root_1, child_1, grandchild_1].each(&:reload) }
    before { [root_2, child_2, grandchild_2].each(&:reload) }

    describe '#root' do
      it { expect(root_1.root).to eq root_1 }
      it { expect{root_1.root}.not_to query_database }
      it { expect(child_1.root).to eq root_1 }
      it { expect(grandchild_1.root).to eq root_1 }

      it { expect(root_2.root).to eq root_2 }
      it { expect{root_2.root}.not_to query_database }
      it { expect(child_2.root).to eq root_2 }
      it { expect(grandchild_2.root).to eq root_2 }
    end

    describe '#self_and_ancestors' do
      it { expect(root_1.self_and_ancestors).to eq [root_1] }
      it { expect{root_1.self_and_ancestors}.not_to query_database }
      it { expect(child_1.self_and_ancestors).to eq [root_1, child_1] }
      it { expect(grandchild_1.self_and_ancestors).to eq [root_1, child_1, grandchild_1] }

      it { expect(child_1.self_and_ancestors).to respond_to :each_with_level }
      it { expect(child_1.self_and_ancestors).to respond_to :each_without_orphans }
    end

    describe '#ancestors' do
      it { expect(root_1.ancestors).to eq [] }
      it { expect{root_1.ancestors}.not_to query_database }
      it { expect(child_1.ancestors).to eq [root_1] }
      it { expect(grandchild_1.ancestors).to eq [root_1, child_1] }

      it { expect(child_1.ancestors).to respond_to :each_with_level }
      it { expect(child_1.ancestors).to respond_to :each_without_orphans }
    end

    describe '#self_and_descendants' do
      it { expect(root_1.self_and_descendants).to eq [root_1, child_1, grandchild_1] }
      it { expect(child_1.self_and_descendants).to eq [child_1, grandchild_1] }
      it { expect(grandchild_1.self_and_descendants).to eq [grandchild_1] }

      it { expect(root_1.self_and_descendants).to respond_to :each_with_level }
      it { expect(root_1.self_and_descendants).to respond_to :each_without_orphans }
    end

    describe '#descendants' do
      it { expect(root_1.descendants).to eq [child_1, grandchild_1] }
      it { expect(child_1.descendants).to eq [grandchild_1] }
      it { expect(grandchild_1.descendants).to eq [] }

      it { expect(root_1.descendants).to respond_to :each_with_level }
      it { expect(root_1.descendants).to respond_to :each_without_orphans }
    end
  end

  include_examples 'ActsAsOrderedTree::Node traversals', :default
  include_examples 'ActsAsOrderedTree::Node traversals', :default_with_counter_cache
  include_examples 'ActsAsOrderedTree::Node traversals', :scoped, :scope_type => 'a'
end