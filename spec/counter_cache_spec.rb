# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, ':counter_cache option', :transactional do
  describe 'Class without counter cache, #children.size' do
    let(:root) { create :default }
    let!(:child_1) { create :default, :parent => root }
    let!(:child_2) { create :default, :parent => root }

    it { expect(root.children.size).to eq 2 }
    it { expect{root.children.size}.to query_database.once }
  end

  describe 'Class with counter cache, #children.size' do
    let(:root) { create :default_with_counter_cache }
    let!(:child_1) { create :default_with_counter_cache, :parent => root }
    let!(:child_2) { create :default_with_counter_cache, :parent => root }

    before { root.reload }

    it { expect(root.children.size).to eq 2 }
    it { expect{root.children.size}.not_to query_database }
  end
end