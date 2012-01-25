require "enumerator"

module ActsAsOrderedTree
  # Enhanced enumerator
  #
  # Allows to use array specific methods like +empty?+, +reverse?+ and so on
  class Iterator < Enumerator
    class NullArgument < ArgumentError; end
    NA = NullArgument.new

    def initialize(*args, &block)
      @enumerator = Enumerator.new(*args, &block)

      super() do |yielder|
        @enumerator.each do |e|
          yielder << e
        end
      end
    end

    # Delegate everything to underlying array
    def method_missing(method_id, *args, &block)
      if method_id !~ /^(__|instance_eval|class|object_id)/
        to_ary!.__send__(method_id, *args, &block)
      else
        super
      end
    end

    private
    def to_ary!
      @enumerator = @enumerator.to_a unless @enumerator.is_a?(Array)
      @enumerator
    end
  end
end