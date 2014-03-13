# coding: utf-8

require 'spec_helper'

require 'acts_as_ordered_tree/persevering_transaction'

describe ActsAsOrderedTree::PerseveringTransaction, :non_transactional do
  def create_transaction(connection = ActiveRecord::Base.connection)
    described_class.new(connection)
  end

  describe 'Transaction state' do
    def transaction
      @transaction ||= create_transaction
    end

    it 'becomes committed only when real transaction ends' do
      transaction.start do
        nested_transaction = create_transaction

        nested_transaction.start { }

        expect(nested_transaction).not_to be_committed
        expect(transaction).not_to be_committed
      end

      expect(transaction).to be_committed
    end

    it 'becomes rolledback when real transaction is rolledback' do
      transaction.start do
        raise ActiveRecord::Rollback
      end

      expect(transaction).to be_rolledback
    end
  end

  describe 'After commit callbacks' do
    it 'executes callbacks only when real transaction commits' do
      executed = []

      outer = create_transaction
      outer.after_commit { executed << 1 }

      outer.start do
        inner = create_transaction
        inner.after_commit { executed << 2 }

        inner.start { }

        expect(executed).to be_empty
      end

      expect(executed).to eq [1, 2]
    end
  end

  describe 'Deadlock handling' do
    def start_in_thread(&block)
      Thread.start do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          trans = create_transaction(connection)
          trans.start(&block)
          trans
        end
      end
    end

    let!(:resource1) { Default.create!(:name => 'resource 1') }
    let!(:resource2) { Default.create!(:name => 'resource 2') }

    # this test randomly fails on Rails 3.1
    it 'Restarts transaction when deadlock occurred' do
      threads = []

      threads << start_in_thread do
        resource1.lock!
        sleep 0.1
        resource2.lock!
        sleep 0.1
      end

      threads << start_in_thread do
        resource2.lock!
        sleep 0.1
        resource1.lock!
        sleep 0.1
      end

      transactions = threads.map(&:value)

      expect(transactions[0]).to be_committed
      expect(transactions[1]).to be_committed
    end
  end

end