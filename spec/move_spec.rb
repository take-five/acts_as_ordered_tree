# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Movement via save', :transactional do
  # root
  #   child 1
  #     child 2
  #     child 3
  #   child 4
  #     child 5
  let(:root) { create :default_with_counter_cache }
  let!(:child1) { create :default_with_counter_cache, :parent => root }
  let!(:child2) { create :default_with_counter_cache, :parent => child1 }
  let!(:child3) { create :default_with_counter_cache, :parent => child1 }
  let!(:child4) { create :default_with_counter_cache, :parent => root }
  let!(:child5) { create :default_with_counter_cache, :parent => child4 }

  def move(node, new_parent, new_position)
    name = "category #{rand(100..1000)}"
    node.parent = new_parent
    node.position = new_position
    node.name = name

    node.save

    expect(node.reload.parent).to eq new_parent
    expect(node.position).to eq new_position
    expect(node.name).to eq name
  end

  context 'when child 2 moved under child 4 to position 1' do
    before { move child2, child4, 1 }

    it { expect(child3.reload.position).to eq 1 } # update lower positions for old siblings
    it { expect(child5.reload.position).to eq 2 } # update lower positions for new siblings
    it { expect(child1.reload.categories_count).to eq 1 } # decrement old counter cache
    it { expect(child4.reload.categories_count).to eq 2 } # increment new counter cache
  end

  context 'when child 2 moved under child 4 to position 2' do
    before { move child2, child4, 2 }

    it { expect(child3.reload.position).to eq 1 } # update lower positions for old siblings
    it { expect(child5.reload.position).to eq 1 }
    it { expect(child2.reload.position).to eq 2 }
    it { expect(child1.reload.categories_count).to eq 1 } # decrement old counter cache
    it { expect(child4.reload.categories_count).to eq 2 } # increment new counter cache
  end

  context 'when level changed' do
    before { move child1, child4, 1 }
    # root
    #   child 4
    #     child 1
    #       child 2
    #       child 3
    #     child 5
    before { [child1, child2, child3, child4, child5].each(&:reload) }

    it { expect(child4.categories_count).to eq 2 }

    it { expect(child1.parent).to eq child4 }
    it { expect(child1.position).to eq 1 }
    it { expect(child1.depth).to eq 2 }

    it { expect(child2.depth).to eq 3 }
    it { expect(child2.position).to eq 1 }

    it { expect(child3.depth).to eq 3 }
    it { expect(child3.position).to eq 2 }

    it { expect(child5.position).to eq 2 }
  end

  context 'when node moved to root' do
    before { move child1, nil, 1 }
    # child 1
    #   child 2
    #   child 3
    # root
    #   child 4
    #     child 5

    before { [root, child1, child2, child3, child4, child5].each(&:reload) }

    it { expect(child1.position).to eq 1 }
    it { expect(child1.depth).to eq 0 }

    it { expect(root.position).to eq 2 }
  end
end