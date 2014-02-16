# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/tree'

describe ActsAsOrderedTree::Tree::Columns do
  let(:klass) { Default }

  shared_examples 'ordered tree column' do |method, option_name, value, klass=Default|
    context 'when existing column name given' do
      subject(:columns) { described_class.new(klass, option_name => value) }

      it { expect(columns.send(method)).to eq value.to_s }
      it { expect(columns.send("#{method}?")).to be true }
    end

    context 'when column name given but klass.columns_hash does not contain given name' do
      subject(:columns) { described_class.new(klass, method => :x) }

      it { expect(columns.send(method)).to be nil }
      it { expect(columns.send("#{method}?")).to be false }
    end

    context 'when column name not given' do
      subject(:columns) { described_class.new(klass, {}) }

      it { expect(columns.send(method)).to be nil }
      it { expect(columns.send("#{method}?")).to be false }
    end
  end

  include_examples 'ordered tree column', :parent, :parent_column, :parent_id
  include_examples 'ordered tree column', :position, :position_column, :position
  include_examples 'ordered tree column', :depth, :depth_column, :depth
  include_examples 'ordered tree column', :counter_cache, :counter_cache, :categories_count do
    context 'when true value as column name given' do
      class Category < ActiveRecord::Base
      end

      subject(:columns) { described_class.new(Category, :counter_cache => true) }

      it { expect(columns.counter_cache).to eq 'categories_count' }
    end
  end

  describe 'scope columns' do
    it 'raises error when any unknown column given' do
      expect{described_class.new(Scoped, :scope => :x)}.to raise_error(described_class::UnknownColumn)
    end

    it 'returns array' do
      subject = described_class.new(Scoped, :scope => :scope_type)

      expect(subject.scope).to eq %w(scope_type)
    end
  end
end