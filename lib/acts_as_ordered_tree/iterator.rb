require "enumerator"

module ActsAsOrderedTree
  # Enhanced enumerator
  #
  # Allows to use array specific methods like +empty?+, +reverse?+ and so on
  class Iterator < Enumerator
    class NullArgument < ArgumentError; end
    NA = NullArgument.new

    extend ActiveSupport::Memoizable

    delegate :[], :<<, :+, :-, :&, :|, :*,
             :at, :concat, :empty?, :fetch, :flatten,
             :insert, :last, :pop, :push,
             :reverse, :reverse_each, :sample, :shift, :shuffle,
             :slice, :uniq, :unshift, :values_at, :to => :to_ary!

    def initialize(*args, &block)
      @enumerator = Enumerator.new(*args, &block)

      super() do |yielder|
        @enumerator.each do |e|
          yielder << e
        end
      end
    end

    # enum.index(obj)           ->  int or nil
    # enum.index {|item| block} ->  int or nil
    #
    #
    #     Returns the index of the first object in <i>self</i> such that is
    #     <code>==</code> to <i>obj</i>. If a block is given instead of an
    #     argument, returns first object for which <em>block</em> is true.
    #     Returns <code>nil</code> if no match is found.
    #
    #        a = [ "a", "b", "c" ]
    #        a.index("b")        #=> 1
    #        a.index("z")        #=> nil
    #        a.index{|x|x=="b"}  #=> 1
    def index(obj = NA, &block)
      # return enumerator without args
      return self if obj == NA && !block_given?

      matcher = obj == NA ? block : proc { |n| n == obj }

      each_with_index do |n, idx|
        return idx if matcher[n]
      end

      nil
    end
    alias find_index index

    # enum.rindex(obj)    ->  int or nil
    #
    #
    #     Returns the index of the last object in <i>self</i> such that is
    #     <code>==</code> to <i>obj</i>. If a block is given instead of an
    #     argument, returns first object for which <em>block</em> is
    #     true. Returns <code>nil</code> if no match is found.
    #
    #        a = [ "a", "b", "b", "b", "c" ]
    #        a.rindex("b")        #=> 3
    #        a.rindex("z")        #=> nil
    #        a.rindex{|x|x=="b"}  #=> 3
    #
    #
    def rindex(obj = NA, &block)
      # return enumerator without args
      return self if obj == NA && !block_given?

      matcher = obj == NA ? block : proc { |n| n == obj }

      matched_idx = nil

      each_with_index do |n, idx|
        matched_idx = idx if matcher[n]
      end

      matched_idx
    end

    # Returns a copy of _self_ with all +nil+ elements removed.
    def compact
      reject(&:nil?)
    end

    private
    def to_ary!
      @enumerator = @enumerator.to_a unless @enumerator.is_a?(Array)
      @enumerator
    end
    memoize :to_ary!
  end
end