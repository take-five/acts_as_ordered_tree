# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Reorder via save', :transactional do
  tree :factory => :default do
    root {
      child_1
      child_2
      child_3
    }
  end

  def reorder(node, position)
    name = "category #{rand(100..1000)}"
    node.position = position
    node.name = name
    expect { node.save! }.not_to raise_error
    expect(node.name).to eq name
  end

  def assert_order(*nodes)
    nodes.each_with_index do |node, index|
      expect(node.reload.position).to eq index + 1
    end
  end

  context 'when I change position to lower' do
    before { reorder child_2, 1 }

    it 'moves node up' do
      assert_order child_2, child_1, child_3
    end
  end

  context 'when I change position to lower' do
    before { reorder child_2, 3 }

    it 'moves node down' do
      assert_order child_1, child_3, child_2
    end
  end

  context 'when I move highest node lower' do
    before { reorder child_1, 3 }

    it 'moves node down' do
      assert_order child_2, child_3, child_1
    end
  end

  context 'when I move lowest node upper' do
    before { reorder child_3, 1 }

    it 'moves node down' do
      assert_order child_3, child_1, child_2
    end
  end

  context 'when I move to very high position' do
    before { reorder child_1, 5 }

    it 'moves node to bottom' do
      assert_order child_2, child_3, child_1
    end
  end

  context 'when I move to zero position' do
    before { reorder child_2, 0 }

    it 'moves it to top' do
      assert_order child_2, child_1, child_3
    end
  end

  context 'when I move to same position' do
    before { reorder child_2, 2 }

    specify 'order remains the same' do
      assert_order child_1, child_2, child_3
    end
  end
end