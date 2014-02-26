# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'before/after add/remove callbacks', :transactional do
  class Class1 < Default
    cattr_accessor :triggered_callbacks

    def self.triggered?(kind, *args)
      if args.any?
        triggered_callbacks.include?([kind, *args])
      else
        triggered_callbacks.any? { |c| c.first == kind }
      end
    end

    acts_as_ordered_tree :before_add => :before_add,
                         :after_add => :after_add,
                         :before_remove => :before_remove,
                         :after_remove => :after_remove

    def run_callback(kind, *args)
      self.class.triggered_callbacks ||= []
      self.class.triggered_callbacks << [kind, self, *args]
      yield if block_given?
    end

    CALLBACKS = [:before, :after, :around].product([:add, :remove, :move, :reorder]).map { |a, b| "#{a}_#{b}".to_sym }

    CALLBACKS.each do |callback|
      define_method(callback) { |*args, &block| run_callback(callback, *args, &block) }
      send(callback, callback) if respond_to?(callback)
    end
  end

  matcher :trigger_callback do |*callbacks, &block|
    match_for_should do |proc|
      @with ||= nil
      Class1.triggered_callbacks = []
      proc.call
      callbacks.all? { |callback| Class1.triggered?(callback, *@with) }
    end

    match_for_should_not do |proc|
      @with ||= nil
      Class1.triggered_callbacks = []
      proc.call
      callbacks.none? { |callback| Class1.triggered?(callback, *@with) }
    end

    chain :with do |*args, &blk|
      @with = args
      @block = blk
    end

    description do
      description = "trigger callbacks #{callbacks.map(&:inspect).join(', ')}"
      description << " with arguments #{@with.inspect}" if @with
      description
    end

    failure_message_for_should do
      "expected that block would #{description}"
    end

    failure_message_for_should_not do
      desc = "expected that block would not #{description}, but following callbacks were triggered:"
      Class1.triggered_callbacks.each do |kind, *args|
        desc << "\n * #{kind.inspect} #{args.inspect}"
      end
      desc
    end
  end
  alias_method :trigger_callbacks, :trigger_callback

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

  it 'does not trigger any callbacks when tree attributes were not changed' do
    expect {
      child2.update_attributes :name => 'x'
    }.not_to trigger_callbacks(*Class1::CALLBACKS)
  end

  it 'does not trigger any callbacks except :before_remove and :after_remove when node is destroyed' do
    expect {
      child2.destroy
    }.not_to trigger_callbacks(*Class1::CALLBACKS - [:before_remove, :after_remove])
  end

  describe '*_add callbacks' do
    let(:new_record) { Class1.new :name => 'child6' }

    it 'fires *_add callbacks when new children added to node' do
      expect {
        child1.children << new_record
      }.to trigger_callbacks(:before_add, :after_add).with(child1, new_record)
    end

    it 'fires *_add callbacks when node is moved from another parent' do
      expect {
        child2.update_attributes!(:parent => child4)
      }.to trigger_callbacks(:before_add, :after_add).with(child4, child2)
    end
  end

  describe '*_remove callbacks' do
    it 'fires *_remove callbacks when node is moved from another parent' do
      expect {
        child2.update_attributes!(:parent => child4)
      }.to trigger_callbacks(:before_remove, :after_remove).with(child1, child2)
    end

    it 'fires *_remove callbacks when node is destroyed' do
      expect {
        child2.destroy
      }.to trigger_callbacks(:before_remove, :after_remove).with(child1, child2)
    end
  end

  describe '*_move callbacks' do
    it 'fires *_move callbacks when node is moved to another parent' do
      expect {
        child2.update_attributes!(:parent => child4)
      }.to trigger_callbacks(:before_move, :around_move, :after_move).with(child2)
    end

    it 'does not trigger *_move callbacks when node is not moved to another parent' do
      expect {
        child2.move_lower
      }.not_to trigger_callbacks(:before_move, :around_move, :after_move)

      expect {
        root.move_to_root
      }.not_to trigger_callbacks(:before_move, :around_move, :after_move)
    end
  end

  describe '*_reorder callbacks' do
    it 'fires *_reorder callbacks when node position is changed but parent not' do
      expect {
        child2.position += 1
        child2.save
      }.to trigger_callbacks(:before_reorder, :around_reorder, :after_reorder).with(child2)
    end

    it 'does not fire *_reorder callbacks when node is moved to another parent' do
      expect {
        child2.move_to_root
      }.not_to trigger_callbacks(:before_reorder, :around_reorder, :after_reorder)
    end
  end

  describe 'Callbacks context' do
    specify 'new parent_id should be available in before_move' do
      expect(child2).to receive(:before_move) { expect(child2.parent_id).to eq child4.id }
      child2.update_attributes! :parent => child4
    end

    specify 'new position should be available in before_reorder' do
      expect(child2).to receive(:before_reorder) { expect(child2.position).to eq 2 }
      child2.move_lower
    end
  end
end