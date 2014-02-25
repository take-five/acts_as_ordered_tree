# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Destroy node', :transactional do
  shared_examples 'destroy ordered tree node' do |model = :default, attrs = {}|
    let(:root) { create model, attrs }
    let!(:child1) { create model, attrs.merge(:parent => root) }
    let!(:grandchild1) { create model, attrs.merge(:parent => child1) }
    let!(:grandchild2) { create model, attrs.merge(:parent => grandchild1) }
    let!(:child2) { create model, attrs.merge(:parent => root) }
    let!(:child3) { create model, attrs.merge(:parent => root) }

    def assert_destroyed(record)
      expect(record.class).not_to exist(record)
    end

    it 'destroys descendants' do
      child1.destroy

      assert_destroyed(grandchild1)
      assert_destroyed(grandchild2)
    end

    it 'decrements lower siblings positions' do
      child1.destroy

      [child2, child3].each(&:reload)

      expect(child2.position).to eq 1
      expect(child3.position).to eq 2
    end

    #it 'decrements parent children counter' do
    #  expect{child1.destroy}.to change{root.children.reload.size}.from(3).to(2)
    #end
  end

  context 'Default model' do
    include_examples 'destroy ordered tree node', :default
  end

  context 'Scoped model' do
    include_examples 'destroy ordered tree node', :scoped, :scope_type => 't'
  end

  context 'Model with counter cache' do
    include_examples 'destroy ordered tree node', :default_with_counter_cache

    it 'decrements parent children counter' do
      expect{child1.destroy}.to change{root.reload.categories_count}.from(3).to(2)
    end
  end
end