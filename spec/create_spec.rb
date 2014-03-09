# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree, 'Create node', :transactional do
  shared_examples 'create ordered tree node' do |model = :default|
    let(:record) { build model }

    before { record.parent = parent }

    context 'when position is nil' do
      before { record.position = nil }

      it 'does not change node parent' do
        expect{record.save}.not_to change(record, :parent)
      end

      it 'puts record to position = 1 when there are no siblings' do
        expect{record.save}.to change(record, :position).from(nil).to(1)
      end

      it 'puts record to bottom position when there are some siblings' do
        create model, :parent => parent

        expect{record.save}.to change(record, :position).from(nil).to(2)
      end

      it 'calculates depth column' do
        if record.ordered_tree.columns.depth?
          expect{record.save}.to change(record, :depth).from(nil).to(parent ? parent.depth + 1 : 0)
        end
      end
    end

    context 'when position != nil' do
      before { record.position = 3 }

      it 'changes position to 1 if siblings is empty' do
        expect{record.save}.to change(record, :position).from(3).to(1)
      end

      it 'changes position to highest if there are too few siblings' do
        create model, :parent => parent

        expect{record.save}.to change(record, :position).from(3).to(2)
      end

      it 'increments position of lower siblings on insert' do
        first = create model, :parent => parent
        second = create model, :parent => parent
        third = create model, :parent => parent

        expect(first.reload.position).to eq 1
        expect(second.reload.position).to eq 2
        expect(third.reload.position).to eq 3

        expect{record.save and third.reload}.to change(third, :position).from(3).to(4)

        expect(first.reload.position).to eq 1
        expect(second.reload.position).to eq 2
        expect(record.reload.position).to eq 3
      end

      it 'calculates depth column' do
        if record.ordered_tree.columns.depth?
          expect{record.save}.to change(record, :depth).from(nil).to(parent ? parent.depth + 1 : 0)
        end
      end
    end
  end

  context 'when parent is nil' do
    include_examples 'create ordered tree node' do
      let(:parent) { nil }
    end
  end

  context 'when parent exists' do
    include_examples 'create ordered tree node' do
      let(:parent) { create :default }
    end
  end

  context 'when parent exists (scoped)' do
    include_examples 'create ordered tree node', :scoped do
      let(:type) { 'scope' }
      let(:parent) { create :scoped, :scope_type => type }

      it 'copies scope columns values from parent node' do
        expect{record.save}.to change(record, :scope_type).to(parent.scope_type)
      end
    end
  end

  describe 'when counter_cache exists' do
    include_examples 'create ordered tree node', :default_with_counter_cache do
      let(:parent) { create :default_with_counter_cache }

      it 'sets counter_cache to 0 for new record' do
        record.save

        expect(record.categories_count).to eq 0
      end

      it 'increments counter_cache of parent' do
        expect{record.save and parent.reload}.to change(parent, :categories_count).by(1)
      end
    end
  end
end