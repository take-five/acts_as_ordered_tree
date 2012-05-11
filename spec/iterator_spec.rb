require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree::Iterator do
  let(:iterator) do
    ActsAsOrderedTree::Iterator.new([1, 2, 3, 4, 2, 3])
  end

  let(:blanks) { ActsAsOrderedTree::Iterator.new([1, nil, 3]) }

  it "should have random access" do
    iterator[1].should eq(2)
    iterator.at(1).should eq(2)
    iterator.fetch(1).should eq(2)
    iterator.values_at(1, 2).should eq([2, 3])
    iterator.last.should eq(3)
    iterator.slice(1, 2).should have(2).items
    iterator.sample.should be_a(Fixnum)
  end

  it "should support operators" do
    (iterator + [5]).should have(7).items
    (iterator - [4]).should have(5).items
    (iterator * 2).should have(12).items
    (iterator & [4]).should have(1).items
    (iterator | [4]).should have(4).items
    iterator.concat([5]).should have(7).items
  end

  it "should find left index" do
    iterator.find_index(2).should eq(1)
    iterator.find_index { |n| n == 2 }.should eq(1)
  end

  it "should find right index" do
    iterator.rindex(2).should eq(4)
    iterator.rindex { |n| n == 2 }.should eq(4)
  end

  it "should be compacted" do
    blanks.compact.should have(2).items
  end

  it "should be mutable" do
    iter = ActsAsOrderedTree::Iterator.new([1, 2])
    iter << 3 # [1, 2, 3]

    iter.should have(3).items

    iter.insert(1, 99) # [1, 99, 2, 3]
    iter.at(1).should eq(99)

    last = iter.pop # [1, 99, 2]
    iter.last.should eq(2)
    last.should eq(3)

    first = iter.shift # [99, 2]
    iter.first.should eq(99)
    first.should eq(1)

    iter.unshift(100) # [100, 99, 2]
    iter.first.should eq(100)

    iter.push(4)
    iter.should have(4).items
    iter.last.should eq(4)
  end

  it "should raise NoMethodError" do
    iter = ActsAsOrderedTree::Iterator.new([1, 2])
    
    lambda { iter.__undefined_method__ }.should raise_error(NoMethodError)
  end
end