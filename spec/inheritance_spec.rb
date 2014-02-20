# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'inheritance without STI', :transactional do
  class BaseCategory < ActiveRecord::Base
    self.table_name = 'categories'

    acts_as_ordered_tree
  end

  class ConcreteCategory < BaseCategory
  end

  class ConcreteCategoryWithScope < BaseCategory
    default_scope { where(arel_table[:name].matches('* %')) }
  end

  let!(:root) { BaseCategory.create(:name => '* root') }
  let!(:child_1) { BaseCategory.create(:name => 'child 1', :parent => root) }
  let!(:child_2) { BaseCategory.create(:name => 'child 2', :parent => child_1) }
  let!(:child_3) { BaseCategory.create(:name => 'child 3', :parent => child_1) }
  let!(:child_4) { BaseCategory.create(:name => '* child 4', :parent => root) }
  let!(:child_5) { BaseCategory.create(:name => '* child 5', :parent => child_4) }
  let!(:child_6) { BaseCategory.create(:name => 'child 6', :parent => child_4) }

  matcher :be_of do |klass|
    match do |relation|
      expect(relation.map(&:class).uniq).to eq [klass]
    end
  end

  shared_examples 'Inheritance test' do |klass|
    describe "#{klass.name}#children" do
      let(:root_node) { root.becomes(klass) }

      it { expect(root_node).to be_a klass }
      it { expect(root_node.children).to be_of klass }
    end

    describe "#{klass.name}#parent" do
      let(:node) { child_5.becomes(klass) }

      it { expect(node.parent).to be_an_instance_of klass }
    end

    describe "#{klass.name}#root" do
      let(:root_node) { root.becomes(klass) }
      let(:node) { child_5.becomes(klass) }

      it { expect(node.root).to eq root_node }
      it { expect(node.root).to be_an_instance_of klass }
    end

    describe "#{klass.name}#descendants" do
      let(:node) { child_4.becomes(klass) }

      it { expect(node.descendants).to be_of klass }
    end

    describe "#{klass.name}#ancestors" do
      let(:node) { child_5.becomes(klass) }

      it { expect(node.ancestors).to be_of klass }
    end
  end

  include_examples 'Inheritance test', BaseCategory
  include_examples 'Inheritance test', ConcreteCategory
  include_examples 'Inheritance test', ConcreteCategoryWithScope do
    let(:klass) { ConcreteCategoryWithScope }

    describe 'ConcreteCategoryWithScope#children' do
      let(:node) { klass.find(child_4.id) }

      it { expect(node).to be_a klass }
      it { expect(node.children).to be_of klass }

      it 'applies class default scope to #children' do
        expect(node.children).to have(1).item
      end
    end

    describe 'ConcreteCategoryWithScope#parent' do
      let(:orphaned) { child_2.becomes(klass) }
      let(:out_of_scope_with_proper_parent) { child_1.becomes(klass) }

      it { expect(orphaned.parent).to be_nil }
      it { expect(out_of_scope_with_proper_parent.parent).to eq root.becomes(klass) }
    end

    describe 'ConcreteCategoryWithScope#descendants' do
      let(:root_node) { klass.find(root.id) }

      it { expect(root_node.descendants).to be_of klass }
      it { expect(root_node.descendants.map(&:id)).to eq [child_4.id, child_5.id] }
    end
  end
end

describe ActsAsOrderedTree, 'inheritance with STI', :transactional do
  class StiRoot < StiExample
  end

  class StiExample1 < StiExample
  end

  class StiExample2 < StiExample
  end

  # build tree
  let!(:root) { StiRoot.create(:name => 'root') }
  let!(:child_1) { StiExample1.create(:name => 'child 1', :parent => root) }
  let!(:child_2) { StiExample1.create(:name => 'child 2', :parent => child_1) }
  let!(:child_3) { StiExample1.create(:name => 'child 3', :parent => child_1) }
  let!(:child_4) { StiExample2.create(:name => 'child 4', :parent => root) }
  let!(:child_5) { StiExample2.create(:name => 'child 5', :parent => child_4) }
  let!(:child_6) { StiExample2.create(:name => 'child 6', :parent => child_4) }

  before { [root, child_1, child_2, child_3, child_4, child_5, child_6].each &:reload }

  describe '#children' do
    it { expect(root.children).to eq [child_1, child_4] }
  end

  describe '#parent' do
    it { expect(child_1.parent).to eq root }
  end

  describe '#descendants' do
    it { expect(root.descendants).to eq [child_1, child_2, child_3, child_4, child_5, child_6] }
  end

  describe '#ancestors' do
    it { expect(child_5.ancestors).to eq [root, child_4] }
  end

  describe '#root' do
    it { expect(child_5.root).to eq root }
  end

  describe '#left_sibling' do
    it { expect(child_4.left_sibling).to eq child_1 }
  end

  describe '#right_sibling' do
    it { expect(child_1.right_sibling).to eq child_4 }
  end

  describe 'predicates' do
    it { expect(root).to be_is_ancestor_of(child_1) }
    it { expect(root).to be_is_or_is_ancestor_of(child_1) }
    it { expect(child_1).to be_is_descendant_of(root) }
    it { expect(child_1).to be_is_or_is_descendant_of(root) }
  end

  describe 'node reload' do
    it { expect(child_1.ordered_tree_node.reload).to eq child_1 }
  end

  describe 'node moving' do
    before { child_4.move_to_child_of(child_1) }

    it { expect(child_4.parent).to eq child_1 }
    it { expect(child_1.children).to include child_4 }
    it { expect(child_1.descendants).to include child_4 }
  end
end