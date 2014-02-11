# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Reorder via save', :transactional do
  let!(:root) { create :default }
  let!(:child1) { create :default, :parent => root }
  let!(:child2) { create :default, :parent => root }
  let!(:child3) { create :default, :parent => root }

  def reorder(node, position)
    node.position = position
    expect { node.save!(:validate => false) }.not_to raise_error
  end

  def assert_order(*nodes)
    nodes.each_with_index do |node, index|
      expect(node.reload.position).to eq index + 1
    end
  end

  context 'when I change position to lower' do
    before { reorder child2, 1 }

    it 'moves node up' do
      assert_order child2, child1, child3
    end
  end

  context 'when I change position to lower' do
    before { reorder child2, 3 }

    it 'moves node down' do
      assert_order child1, child3, child2
    end
  end

  context 'when I move highest node lower' do
    before { reorder child1, 3 }

    it 'moves node down' do
      assert_order child2, child3, child1
    end
  end

  context 'when I move lowest node upper' do
    before { reorder child3, 1 }

    it 'moves node down' do
      assert_order child3, child1, child2
    end
  end

  context 'when I move to very high position' do
    before { reorder child1, 5 }

    it 'moves node to bottom' do
      assert_order child2, child3, child1
    end
  end

  context 'when I move to zero position' do
    before { reorder child2, 0 }

    it 'moves it to top' do
      assert_order child2, child1, child3
    end
  end

  context 'when I move to same position' do
    before { reorder child2, 2 }

    specify 'order remains the same' do
      assert_order child1, child2, child3
    end
  end
end