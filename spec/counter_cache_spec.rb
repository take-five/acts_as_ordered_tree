# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, ':counter_cache option', :transactional do
  describe 'Class without counter cache, #children.size' do
    tree :factory => :default do
      root {
        child_1
        child_2
      }
    end

    it { expect(root.children.size).to eq 2 }
    it { expect{root.children.size}.to query_database.once }
  end

  describe 'Class with counter cache, #children.size' do
    tree :factory => :default_with_counter_cache do
      root {
        child_1
        child_2
      }
    end

    before { root.reload }

    it { expect(root.children.size).to eq 2 }
    it { expect{root.children.size}.not_to query_database }
  end
end