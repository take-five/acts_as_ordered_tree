# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/relation/preloaded'

describe ActsAsOrderedTree::Relation::Preloaded, :transactional do
  let!(:records) { create_list :default, 2 }

  def count_queries
    queries = []

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, sql|
      queries << sql
    end

    yield

    ActiveSupport::Notifications.unsubscribe(subscriber)

    queries.count
  end

  def relation
    Default.where(nil).extending(described_class)
  end

  context 'when preloaded records were not set' do
    subject { relation.to_a }

    it { expect(subject).to eq records }
    it { expect(subject).not_to be records }
    it { expect(count_queries{subject}).to eq 1 }
  end

  context 'when preloaded records were set directly' do
    subject { relation.records(records).to_a }

    it { expect(subject).to eq records }
    it { expect(subject).to be records }
    it { expect(count_queries{subject}).to eq 0 }
  end
end