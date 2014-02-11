# Rails 3.0 lacks of :logger method

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      attr_reader :logger unless method_defined?(:logger)
    end
  end
end