module RSpec::Matchers

  # it { should fire_callback(:around_move).on(:save) }
  # it { should fire_callback(:after_move).on(:move_to_left_of, lft_id) }
  # it { should fire_callback(:around_move).on(:save).at_least(1).time }
  # it { should fire_callback(:around_move).on(:save).at_most(2).times }
  # it { should fire_callback(:around_move).on(:save).exactly(2).times }
  # it { should fire_callback(:around_move).on(:save).once }
  # it { should fire_callback(:around_move).on(:save).twice }
  def fire_callback(name)
    FireCallbackMatcher.new(name)
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

    def on(method, *args)
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

        called = @subject.instance_variable_get ivar

        (@limit_min..@limit_max || 1000).cover?(called)
      end
    end

    def failure_message_for_should
      "expected #@subject to fire callback #@callback when #@method is called (#@limit_min..#@limit_max) times"
    end

    def failure_message_for_should_not
      "expected #@subject not to fire callback #@callback when #@method is called (#@limit_min..#@limit_max) times"
    end

    private
    def with_temporary_callback
      kind, name = @callback.split('_')

      method_name = :"__temporary_callback_#{object_id}"

      @subject.class.class_eval <<-CODE
        def #{method_name}
          @#{method_name} ||= 0
          @#{method_name} + 1
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
end