# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Destroy node', :transactional do
  shared_examples 'destroy ordered tree node' do |model = :default, attrs = {}|
    tree :factory => model, :attributes => attrs do
      root {
        child_1 {
          grandchild_1 {
            grandchild_2
          }
        }
        child_2
        child_3
      }
    end

    def assert_destroyed(record)
      expect(record.class).not_to exist(record.id)
    end

    it 'destroys descendants' do
      child_1.destroy

      assert_destroyed(grandchild_1)
      assert_destroyed(grandchild_2)
    end

    it 'decrements lower siblings positions' do
      child_1.destroy

      [child_2, child_3].each(&:reload)

      expect(child_2.position).to eq 1
      expect(child_3.position).to eq 2
    end
  end

  context 'Default model' do
    include_examples 'destroy ordered tree node', :default
  end

  context 'Scoped model' do
    include_examples 'destroy ordered tree node', :scoped, :scope_type => 't'
  end

  context 'Model with counter cache' do
    include_examples 'destroy ordered tree node', :default_with_counter_cache

    before { root.reload }

    it 'decrements parent children counter' do
      expect{child_1.destroy and root.reload}.to change(root, :categories_count).from(3).to(2)
    end
  end
end