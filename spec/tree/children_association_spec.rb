# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Tree::ChildrenAssociation, :transactional do
  shared_examples 'ChildrenAssociation' do |model|
    describe model.to_s do
      tree :factory => model do
        root {
          child_1
          child_2
          child_3
        }
      end

      let(:klass) { current_tree }

      describe 'joining to association' do
        let(:relation) { klass.joins(:children) }

        it { expect(relation).to eq [root, root, root] }
      end

      describe 'loading association' do
        it { expect(root.children.size).to eq 3 }
        it { expect(root.children).to eq [child_1, child_2, child_3] }

        it { expect{root.children.to_a}.to query_database(/ORDER BY .*position/) }
      end

      describe 'eager_loading association' do
        let(:relation) { klass.eager_load(:children).order(klass.arel_table[:id]) }
        let(:first) { relation.to_a.first }

        it { expect(relation).to eq [root, child_1, child_2, child_3] }
        it { expect(first.children).to be_loaded }
        it { expect(first.children.size).to eq 3 }
      end

      describe 'preloading association' do
        let(:relation) { klass.preload(:children).order(klass.arel_table[:id]) }
        let(:first) { relation.to_a.first }

        it { expect(relation).to eq [root, child_1, child_2, child_3] }
        it { expect(first.children).to be_loaded }
        it { expect(first.children.size).to eq 3 }
      end

      describe 'preloading association (via includes method)' do
        let(:relation) { klass.includes(:children).order(klass.arel_table[:id]) }
        let(:first) { relation.to_a.first }

        it { expect(relation).to eq [root, child_1, child_2, child_3] }
        it { expect(first.children).to be_loaded }
        it { expect(first.children.size).to eq 3 }
      end

      describe 'extensions' do
        it { expect(root.children).to respond_to :each_with_level }
        it { expect(root.children).to respond_to :each_without_orphans }
      end
    end
  end

  include_examples 'ChildrenAssociation', :default
  include_examples 'ChildrenAssociation', :scoped
end