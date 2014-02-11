# coding: utf-8

require 'acts_as_ordered_tree/compatibility/active_record/connection_adapters/abstract_adapter'

module ActsAsOrderedTree
  class PerseveringTransaction
    # Which errors should be treated as deadlocks
    DEADLOCK_MESSAGES = Regexp.new [
      'Deadlock found when trying to get lock',
      'Lock wait timeout exceeded',
      'deadlock detected',
      'database is locked'
    ].join(?|).freeze
    # How many times we should retry transaction
    RETRY_COUNT = 10

    attr_reader :connection, :attempts

    def initialize(connection)
      @connection = connection
      @attempts = 0
    end

    # Starts persevering transaction
    def start(&block)
      @attempts += 1

      connection.transaction(&block)
    rescue ActiveRecord::StatementInvalid => error
      raise unless connection.open_transactions.zero?
      raise unless error.message =~ DEADLOCK_MESSAGES
      raise if attempts >= RETRY_COUNT

      connection.logger.info "Deadlock detected on attempt #{attempts}, restarting transaction"

      pause and retry
    end

    private
    def pause
      sleep(rand(attempts) * 0.1)
    end
  end
end