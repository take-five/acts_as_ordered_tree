module ActsAsOrderedTree
  module TenaciousTransaction
    DEADLOCK_MESSAGES = /Deadlock found when trying to get lock|Lock wait timeout exceeded|deadlock detected/.freeze
    RETRY_COUNT = 10

    # Partially borrowed from awesome_nested_set
    def tenacious_transaction(&block) #:nodoc:
      return transaction(&block) if @in_tenacious_transaction

      @in_tenacious_transaction = true
      retry_count = 0
      begin
        transaction(&block)
      rescue ActiveRecord::StatementInvalid => error
        raise unless self.class.connection.open_transactions.zero?
        raise unless error.message =~ DEADLOCK_MESSAGES
        raise unless retry_count < RETRY_COUNT
        retry_count += 1

        logger.info "Deadlock detected on retry #{retry_count}, restarting transaction"

        sleep(rand(retry_count)*0.1) # Aloha protocol

        retry
      ensure
        @in_tenacious_transaction = false
      end
    end
  end
end