module RSpec::Matchers
  # it { expect{...}.to query_database.once }
  # it { expect{...}.to query_database.at_most(2).times }
  # it { expect{...}.not_to query_database }
  def query_database(regexp = nil)
    QueryDatabaseMatcher.new(regexp)
  end

  # example { expect(record1, record2, record3).to be_sorted }
  def be_sorted
    OrderMatcher.new
  end

  class QueryDatabaseMatcher
    def initialize(regexp)
      @min = nil
      @max = nil
      @regexp = regexp
    end

    def times
      self
    end
    alias time times

    def at_least(times)
      @min = times == :once ? 1 : times
      self
    end

    def at_most(times)
      @max = times == :once ? 1 : times
      self
    end

    def exactly(times)
      at_least(times).at_most(times)
      self
    end

    def once
      exactly(1)
    end

    def twice
      exactly(2)
    end

    def matches?(subject)
      record_queries { subject.call }

      result = expected_queries_count.include?(@queries.size)
      result &&= @queries.any? { |q| @regexp === q } if @regexp
      result
    end

    def description
      desc = 'query database'

      if @min && !@max
        desc << ' at least ' << human_readable_count(@min)
      end

      if @max && !@min
        desc << ' at most ' << human_readable_count(@max)
      end

      if @min && @max && @min != @max
        desc << " #{@min}..#{@max} times"
      end

      if @min && @max && @min == @max
        desc << ' ' << human_readable_count(@min)
      end

      if @regexp
        desc << ' and match ' << @regexp.to_s
      end

      desc
    end

    def failure_message_for_should(negative = false)
      verb = negative ? 'not to' : 'to'
      message = "expected given block #{verb} #{description}, but #{@queries.size} queries sent"

      if @queries.any?
        message << ":\n#{@queries.each_with_index.map { |q, i| "#{i+1}. #{q}"}.join("\n")}"
      end

      message
    end

    def failure_message_for_should_not
      failure_message_for_should(true)
    end

    private
    def record_queries
      @queries = []

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, sql|
        next if sql[:name] == 'SCHEMA'

        @queries << sql[:sql]
      end

      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def expected_queries_count
      ((@min||1)..@max || 10000)
    end

    def human_readable_count(n)
      n == 1 ? 'once' : "#{n} times"
    end
  end

  class OrderMatcher
    def matches?(*records)
      @records = Array.wrap(records).flatten

      @records.sort_by { |record| record.reload.ordered_tree_node.position } == @records
    end

    def failure_message_for_should
      "expected #{@records.inspect} to be ordered by position, but they are not"
    end

    def failure_message_for_should_not
      "expected #{@records.inspect} not to be ordered by position, but they are"
    end
  end
end

# Taken from rspec-rails
module ::ActiveModel::Validations
  # Extension to enhance `should have` on AR Model instances.  Calls
  # model.valid? in order to prepare the object's errors object.
  #
  # You can also use this to specify the content of the error messages.
  #
  # @example
  #
  #     model.should have(:no).errors_on(:attribute)
  #     model.should have(1).error_on(:attribute)
  #     model.should have(n).errors_on(:attribute)
  #
  #     model.errors_on(:attribute).should include("can't be blank")
  def errors_on(attribute)
    self.valid?
    [self.errors[attribute]].flatten.compact
  end
  alias :error_on :errors_on
end