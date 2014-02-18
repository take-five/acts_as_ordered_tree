module RSpec::Matchers

  # it { should fire_callback(:around_move).when_calling(:save) }
  # it { should fire_callback(:after_move).when_calling(:move_to_left_of, lft_id) }
  # it { should fire_callback(:around_move).owhen_callingn(:save).at_least(1).time }
  # it { should fire_callback(:around_move).when_calling(:save).at_most(2).times }
  # it { should fire_callback(:around_move).when_calling(:save).exactly(2).times }
  # it { should fire_callback(:around_move).when_calling(:save).once }
  # it { should fire_callback(:around_move).when_calling(:save).twice }
  def fire_callback(name)
    FireCallbackMatcher.new(name)
  end

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

  class FireCallbackMatcher
    attr_reader :failure_message, :negative_failure_message

    def initialize(callback_name)
      @callback = callback_name
      @method = :save
      @args = []

      @limit_min = 1
      @limit_max = nil
    end

    def when_calling(method, *args)
      @method = method
      @args = args
      self
    end

    def times
      self
    end
    alias time times

    def at_least(times)
      @limit_min = times == :once ? 1 : times
      self
    end

    def at_most(times)
      @limit_max = times == :once ? 1 : times
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

    def description
      "fire callback #@callback when #@method is called"
    end

    def matches?(subject)
      @subject = subject

      raise 'Method required' unless @method

      with_temporary_callback do |ivar|
        @subject.send(@method, *@args)

        @received = @subject.instance_variable_get ivar

        (@limit_min..@limit_max || 1000).include?(@received)
      end
    end

    def failure_message_for_should
      "expected #{@subject.inspect} to fire callback :#@callback when #@method is called (#@limit_min..#@limit_max) times, #@received times fired"
    end

    def failure_message_for_should_not
      "expected #{@subject.inspect} not to fire callback :#@callback when #@method is called (#@limit_min..#@limit_max) times, #@received times fired"
    end

    private
    def with_temporary_callback
      kind, name = @callback.to_s.split('_')

      method_name = :"__temporary_callback_#{object_id.abs}"

      @subject.class.class_eval <<-CODE
        def #{method_name}
          @#{method_name} ||= 0
          @#{method_name} += 1
          yield if block_given?
        end
        #{kind}_#{name} :#{method_name}
      CODE

      result = yield :"@#{method_name}"

      @subject.class.class_eval <<-CODE
        skip_callback :#{name}, :#{kind}, :#{method_name}
        undef_method :#{method_name}
      CODE

      result
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