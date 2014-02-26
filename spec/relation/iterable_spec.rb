# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/relation/iterable'

describe ActsAsOrderedTree::Relation::Iterable, :transactional do
  shared_examples 'iterable' do |model|
    # root_1
    #   child_1
    #     child_2
    #   child_3
    #     child_4
    #     child_5
    # root_2
    #   child_6
    let!(:root_1) { create model }
    let!(:child_1) { create model, :parent => root_1 }
    let!(:child_2) { create model, :parent => child_1 }
    let!(:child_3) { create model, :parent => root_1 }
    let!(:child_4) { create model, :parent => child_3 }
    let!(:child_5) { create model, :parent => child_3 }
    let!(:root_2) { create model }
    let!(:child_6) { create model, :parent => root_2 }

    let(:klass) { root_1.class }

    describe '#each_with_level' do
      it 'iterates over collection and yields level' do
        relation = klass.order(:id).extending(described_class)

        expect { |b|
          relation.each_with_level(&b)
        }.to yield_successive_args [root_1, 0],
                                   [child_1, 1],
                                   [child_2, 2],
                                   [child_3, 1],
                                   [child_4, 2],
                                   [child_5, 2],
                                   [root_2, 0],
                                   [child_6, 1]
      end

      it 'computes level relative to first selected node' do
        expect { |b|
          root_1.descendants.extending(described_class).each_with_level(&b)
        }.to yield_successive_args [child_1, 1],
                                   [child_2, 2],
                                   [child_3, 1],
                                   [child_4, 2],
                                   [child_5, 2]
      end
    end

    describe '#each_without_orphans' do
      let(:relation) { klass.order(:id).extending(described_class) }

      it 'iterates over collection' do
        expect { |b|
          relation.each_without_orphans(&b)
        }.to yield_successive_args root_1,
                                   child_1,
                                   child_2,
                                   child_3,
                                   child_4,
                                   child_5,
                                   root_2,
                                   child_6
      end

      it 'iterates over collection and discards orphans' do
        expect { |b|
          relation.where('id != ?', child_3.id).each_without_orphans(&b)
        }.to yield_successive_args root_1,
                                   child_1,
                                   child_2,
                                   root_2,
                                   child_6
      end

      it 'iterates over collection and discards orphans' do
        expect { |b|
          relation.where('id != ?', root_2.id).each_without_orphans(&b)
        }.to yield_successive_args root_1,
                                   child_1,
                                   child_2,
                                   child_3,
                                   child_4,
                                   child_5
      end

      it 'iterates over collection and discards orphans' do
        expect { |b|
          relation.where('id != ?', root_1.id).each_without_orphans(&b)
        }.to yield_successive_args root_2,
                                   child_6
      end
    end
  end

  describe 'Model with cached level' do
    it_behaves_like 'iterable', :default
  end

  describe 'Model without cached level' do
    it_behaves_like 'iterable', :default_without_depth
  end
end