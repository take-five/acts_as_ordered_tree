# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/relation/preloaded'

describe ActsAsOrderedTree::Relation::Preloaded, :transactional do
  let!(:records) { create_list :default, 2 }

  def relation
    Default.where(nil).extending(described_class)
  end

  context 'when preloaded records were not set' do
    it { expect(relation).to eq records }
    it { expect(relation.to_a).not_to be records }
    it { expect{relation.to_a}.to query_database.once }
  end

  context 'when preloaded records were set directly' do
    let(:preloaded) { relation.records(records) }

    it { expect(preloaded).to eq records }

    it { expect(preloaded.to_a).to be records }
    it { expect{preloaded.to_a}.not_to query_database }

    it { expect(preloaded.size).to eq 2 }
    it { expect{preloaded.size}.not_to query_database }

    context 'when preloaded relation was extended' do
      let(:extended) { preloaded.extending(Module.new) }

      it { expect(extended).to eq records }

      it { expect(extended.to_a).to be records }
      it { expect{extended.to_a}.not_to query_database }

      it { expect(extended.size).to eq 2 }
      it { expect{extended.size}.not_to query_database }
    end

    describe '#reverse_order' do
      it { expect(preloaded.reverse_order).not_to be preloaded }
      it { expect(preloaded.reverse_order.size).to eq 2 }
      it { expect(preloaded.reverse_order).to eq records.reverse }
      it { expect{preloaded.reverse_order.to_a}.not_to query_database }
    end

    describe '#reverse_order!' do
      it { expect(preloaded.reverse_order!).to be preloaded }
      it { expect(preloaded.reverse_order!.size).to eq 2 }
      it { expect(preloaded.reverse_order!.to_a).to eq records.reverse }
      it { expect{preloaded.reverse_order!.to_a}.not_to query_database }
    end
  end
end