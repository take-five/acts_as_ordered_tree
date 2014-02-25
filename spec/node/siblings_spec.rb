# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Siblings, :transactional do
  shared_examples 'siblings' do |model|
    # silence pending examples
    #
    # @todo fix all xits
    def self.xit(*) end

    let(:root) { create model }
    let(:items) { create_list model, 3, :parent => root }

    # first
    it { expect(items.first.self_and_siblings).to eq items }
    it { expect(items.first.siblings).to eq [items.second, items.last] }

    it { expect(items.first.left_sibling).to be nil }
    it { expect(items.first.right_sibling).to eq items.second }

    it { expect(items.first.left_siblings).to be_empty }
    it { expect(items.first.right_siblings).to eq [items.second, items.last] }

    # second
    it { expect(items.second.self_and_siblings).to eq items }
    it { expect(items.second.siblings).to eq [items.first, items.last] }

    it { expect(items.second.left_sibling).to eq items.first }
    it { expect(items.second.right_sibling).to eq items.last }

    it { expect(items.second.left_siblings).to eq [items.first] }
    it { expect(items.second.right_siblings).to eq [items.last] }

    # last
    it { expect(items.last.self_and_siblings).to eq items }
    it { expect(items.last.siblings).to eq [items.first, items.second] }

    it { expect(items.last.left_sibling).to eq items.second }
    it { expect(items.last.right_sibling).to be nil }

    it { expect(items.last.left_siblings).to eq [items.first, items.second] }
    it { expect(items.last.right_siblings).to be_empty }

    context 'trying to set left or right sibling with random object' do
      def self.expect_type_mismatch_on(value)
        it "throws error when #{value.class} given" do
          expect {
            items.first.left_sibling = value
          }.to raise_error ActiveRecord::AssociationTypeMismatch

          expect {
            items.first.right_sibling = value
          }.to raise_error ActiveRecord::AssociationTypeMismatch
        end
      end

      def self.generate_class
        Class.new(ActiveRecord::Base){ self.table_name = 'categories' }
      end

      expect_type_mismatch_on(generate_class.new)
      expect_type_mismatch_on(nil)
    end

    context 'when left sibling is set' do
      context 'and new left sibling has same parent' do
        context 'and new left sibling is higher' do
          let(:item) { items.last }
          before { item.left_sibling = items.first }

          it { expect(item.parent).to eq items.first.parent }
          it { expect(item.position).to eq 2 }

          xit { expect(item.left_sibling).to eq items.first }
          xit { expect(item.right_siblings).to eq [items.second] }
        end

        context 'and new left sibling is lower' do
          let(:item) { items.first }
          before { item.left_sibling = items.last }

          it { expect(item.parent).to eq items.first.parent }
          it { expect(item.position).to eq 3 }

          xit { expect(item.left_sibling).to eq items.last }
          xit { expect(item.left_siblings).to eq [items.second, items.last] }
        end
      end

      context 'and new left sibling has other parent' do
        let(:item) { items.first }
        before { item.left_sibling = root }

        it { expect(item.parent).to be nil }
        it { expect(item.position).to eq 2 }

        xit { expect(item.left_sibling).to eq root }
      end

      context 'via #left_sibling_id=' do
        let(:item) { items.first }

        it 'throws error when non-existent ID given' do
          expect {
            item.left_sibling_id = -1
          }.to raise_error ActiveRecord::RecordNotFound
        end

        it 'delegates to #left_sibling=' do
          new_sibling = items.last

          expect(item.ordered_tree_node).to receive(:left_sibling=).with(new_sibling)
          item.left_sibling_id = new_sibling.id
        end
      end
    end

    context 'when right sibling is set' do
      context 'and new right sibling has same parent' do
        context 'and new right sibling is higher' do
          let(:item) { items.last }
          before { item.right_sibling = items.first }

          it { expect(item.parent).to eq items.first.parent }
          it { expect(item.position).to eq 1 }

          xit { expect(item.right_sibling).to eq item.first }
          xit { expect(item.left_siblings).to be_empty }
          xit { expect(item.right_siblings).to eq [items.first, items.second] }
        end

        context 'and new right sibling is lower' do
          let(:item) { items.first }
          before { item.right_sibling = items.last }

          it { expect(item.parent).to eq items.first.parent }
          it { expect(item.position).to eq 2 }

          xit { expect(item.right_sibling).to eq items.last }
          xit { expect(item.right_siblings).to eq [items.last] }

          xit { expect(item.left_sibling).to eq items.first }
          xit { expect(item.left_siblings).to eq [items.first] }
        end
      end

      context 'and new right sibling has other parent' do
        let(:item) { items.first }
        before { item.right_sibling = root }

        it { expect(item.parent).to be nil }
        it { expect(item.position).to eq 1 }

        xit { expect(item.right_sibling).to eq root }
      end

      context 'via #right_sibling_id=' do
        let(:item) { items.first }

        it 'throws error when non-existent ID given' do
          expect {
            item.right_sibling_id = -1
          }.to raise_error ActiveRecord::RecordNotFound
        end

        it 'delegates to #right_sibling=' do
          new_sibling = items.last

          expect(item.ordered_tree_node).to receive(:right_sibling=).with(new_sibling)
          item.right_sibling_id = new_sibling.id
        end
      end
    end
  end

  context 'Tree without scopes' do
    include_examples 'siblings', :default
    include_examples 'siblings', :default_with_counter_cache
  end

  context 'Tree with scope' do
    let!(:items_1) { create_list :scoped, 3, :scope_type => 's1' }
    let!(:items_2) { create_list :scoped, 3, :scope_type => 's2' }

    include_examples 'siblings', :scoped do
      let(:items) { items_1 }
    end
    include_examples 'siblings', :scoped do
      let(:items) { items_2 }
    end
  end
end