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
    node.parent = new_parent
    node.position = new_position

    node.save

    expect(node.reload.parent).to eq new_parent
    expect(node.position).to eq new_position
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

describe ActsAsOrderedTree, 'before/after add/remove callbacks', :transactional do
  class Class1 < Default
    cattr_accessor :triggered_callbacks

    def self.triggered?(kind, *args)
      triggered_callbacks.include?([kind, *args])
    end

    acts_as_ordered_tree :before_add => :before_add,
                         :after_add => :after_add,
                         :before_remove => :before_remove,
                         :after_remove => :after_remove

    def run_callback(kind, arg)
      self.class.triggered_callbacks ||= []
      self.class.triggered_callbacks << [kind, self, arg]
    end

    def before_remove(record)
      run_callback(:before_remove, record)
    end

    def after_remove(record)
      run_callback(:after_remove, record)
    end

    def before_add(record)
      run_callback(:before_add, record)
    end

    def after_add(record)
      run_callback(:after_add, record)
    end
  end

  # root
  #   child 1
  #     child 2
  #     child 3
  #   child 4
  #     child 5
  let(:root) { Class1.create :name => 'root' }
  let!(:child1) { Class1.create :name => 'child1', :parent => root }
  let!(:child2) { Class1.create :name => 'child2', :parent => child1 }
  let!(:child3) { Class1.create :name => 'child3', :parent => child1 }
  let!(:child4) { Class1.create :name => 'child4', :parent => root }
  let!(:child5) { Class1.create :name => 'child5', :parent => child4 }

  def test_callback(record, kind, expected_arg, &block)
    Class1.triggered_callbacks = []

    expect(&block).to change{Class1.triggered?(kind, record, expected_arg)}.to(true)
  end

  describe '*_add callbacks' do
    let(:new_record) { Class1.new :name => 'child6' }

    it 'fires before_add callback when new children added to node' do
      test_callback(child1, :before_add, new_record) { child1.children << new_record }
    end

    it 'fires after_add callback when new children added to node' do
      test_callback(child1, :after_add, new_record) { child1.children << new_record }
    end

    it 'fires before_add callback when node is moved from another parent' do
      test_callback(child4, :before_add, child2) { child2.update_attributes!(:parent => child4) }
    end

    it 'fires after_add callback when node is moved from another parent' do
      test_callback(child4, :after_add, child2) { child2.update_attributes!(:parent => child4) }
    end
  end

  describe '*_remove callbacks' do
    it 'fires before_remove callback when node is moved from another parent' do
      test_callback(child1, :before_remove, child2) { child2.update_attributes!(:parent => child4) }
    end

    it 'fires after_remove callback when node is moved from another parent' do
      test_callback(child1, :after_remove, child2) { child2.update_attributes!(:parent => child4) }
    end

    it 'fires before_remove callback when node is destroyed' do
      test_callback(child1, :before_remove, child2) { child2.destroy }
    end

    it 'fires after_remove callback when node is destroyed' do
      test_callback(child1, :after_remove, child2) { child2.destroy }
    end
  end
end