require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree do
  describe "defaults" do
    subject { Default }

    its(:parent_column) { should eq :parent_id }
    its(:position_column) { should eq :position }
    its(:depth_column) { should eq :depth }
    its(:children_counter_cache_column) { be_nil }

    context "instance" do
      subject { Default.new }

      it { should_not allow_mass_assignment_of(:position) }
      it { should_not allow_mass_assignment_of(:depth) }
    end
  end

  describe "default with counter cache" do
    subject { DefaultWithCounterCache }

    its(:children_counter_cache_column) { should eq :categories_count }
  end

  describe "renamed columns" do
    subject { RenamedColumns }

    its(:parent_column) { should eq :mother_id }
    its(:position_column) { should eq :red }
    its(:depth_column) { should eq :pitch }

    context "instance" do
      subject { RenamedColumns.new }

      it { should_not allow_mass_assignment_of(:red) }
      it { should_not allow_mass_assignment_of(:pitch) }
    end
  end

  it "creation_with_altered_column_names" do
    lambda {
      RenamedColumns.create!()
    }.should_not raise_exception
  end

  describe ".roots" do
    # create fixture
    before { FactoryGirl.create_list(:default, 3) }

    subject { Default.roots }

    its(:entries) { should eq Default.where(:parent_id => nil).order(:position).to_a }
  end

  describe ".leaves" do
    # create fixture
    let(:root) { FactoryGirl.create(:default_with_counter_cache) }
    before { FactoryGirl.create_list(:default_with_counter_cache, 2, :parent => root) }

    subject { DefaultWithCounterCache }

    it { should respond_to(:leaves) }
    its(:leaves) { should have(2).items }
  end

  describe ".root" do
    # create fixture
    let(:root) { FactoryGirl.create :default }

    context "single" do
      subject { root }

      its(:position) { should eq 1 }
    end

    context "list" do
      before { root; FactoryGirl.create_list(:default, 3) }

      subject { Default }

      its(:root) { should eq root }
    end
  end

  describe "#root?, #child?, #leaf? and #root" do
    # create fixture
    let!(:root) { FactoryGirl.create :default }
    let!(:child) { FactoryGirl.create :default, :parent => root }
    let!(:grandchild) { FactoryGirl.create :default, :parent => child }

    specify { root.should be_root }
    specify { root.should_not be_child }
    specify { root.should_not be_leaf }
    specify { root.root.should eq root }
    specify { root.level.should eq 0 }

    specify { child.should_not be_root }
    specify { child.should be_child }
    specify { child.should_not be_leaf }
    specify { child.root.should eq root }
    specify { child.level.should eq 1 }

    specify { grandchild.should_not be_root }
    specify { grandchild.should be_child }
    specify { grandchild.should be_leaf }
    specify { grandchild.root.should eq root }
    specify { grandchild.level.should eq 2 }

    it "new record cannot be leaf" do
      record = FactoryGirl.build :default
      record.should_not be_leaf
    end
  end

  describe "#self_and_ancestors" do
    # create fixture
    let!(:root) { FactoryGirl.create :default }
    let!(:child) { FactoryGirl.create :default, :parent => root }
    let!(:grandchild) { FactoryGirl.create :default, :parent => child }

    context "leaf" do
      subject { grandchild.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(3).items }
      its(:first) { should eq root }
      its(:last) { should eq subject }
    end

    context "child" do
      subject { child.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(2).items }
      its(:first) { should eq root }
      its(:last) { should eq subject }
    end

    context "root" do
      subject { root.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(1).item }
      its(:first) { should eq root }
    end
  end

  describe "#ancestors" do
    # create fixture
    let!(:root) { FactoryGirl.create :default }
    let!(:child) { FactoryGirl.create :default, :parent => root }
    let!(:grandchild) { FactoryGirl.create :default, :parent => child }

    context "leaf" do
      subject { grandchild.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(2).items }
      its(:first) { should eq root }
      its(:last) { should eq child }
    end

    context "child" do
      subject { child.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(1).item }
      its(:first) { should eq root }
    end

    context "root" do
      subject { root.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should be_empty }
    end
  end

  describe "#self_and_descendants" do
    # create fixture
    let!(:root) { FactoryGirl.create :default }
    let!(:child) { FactoryGirl.create :default, :parent => root }
    let!(:grandchild) { FactoryGirl.create :default, :parent => child }

    context "leaf" do
      subject { grandchild.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(1).item }
      its(:first) { should eq grandchild }
    end

    context "child" do
      subject { child.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(2).items }
      its(:first) { should eq child }
      its(:last) { should eq grandchild }
    end

    context "root" do
      subject { root.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should be_loaded }
      it { should have(3).items }
      its(:first) { should eq root }
      its(:last) { should eq grandchild }
    end
  end

  describe "#is_descendant_of?, #is_or_is_descendant_of?, #is_ancestor_of?, #is_or_is_ancestor_of?" do
    # create fixture
    let!(:root) { FactoryGirl.create :default }
    let!(:child) { FactoryGirl.create :default, :parent => root }
    let!(:grandchild) { FactoryGirl.create :default, :parent => child }

    context "grandchild" do
      subject { grandchild }

      it { should be_is_descendant_of(root) }
      it { should be_is_or_is_descendant_of(root) }
      it { should_not be_is_ancestor_of(root) }
      it { should_not be_is_or_is_ancestor_of(root) }

      it { should be_is_descendant_of(child) }
      it { should be_is_or_is_descendant_of(child) }
      it { should_not be_is_ancestor_of(child) }
      it { should_not be_is_or_is_ancestor_of(child) }

      it { should_not be_is_descendant_of(grandchild) }
      it { should be_is_or_is_descendant_of(grandchild) }
      it { should_not be_is_ancestor_of(grandchild) }
      it { should be_is_or_is_ancestor_of(grandchild) }
    end

    context "child" do
      subject { child }

      it { should be_is_descendant_of(root) }
      it { should be_is_or_is_descendant_of(root) }
      it { should_not be_is_ancestor_of(root) }
      it { should_not be_is_or_is_ancestor_of(root) }

      it { should_not be_is_descendant_of(child) }
      it { should be_is_or_is_descendant_of(child) }
      it { should_not be_is_ancestor_of(child) }
      it { should be_is_or_is_ancestor_of(child) }

      it { should_not be_is_descendant_of(grandchild) }
      it { should_not be_is_or_is_descendant_of(grandchild) }
      it { should be_is_ancestor_of(grandchild) }
      it { should be_is_or_is_ancestor_of(grandchild) }
    end

    context "root" do
      subject { root }

      it { should_not be_is_descendant_of(root) }
      it { should be_is_or_is_descendant_of(root) }
      it { should_not be_is_ancestor_of(root) }
      it { should be_is_or_is_ancestor_of(root) }

      it { should_not be_is_descendant_of(child) }
      it { should_not be_is_or_is_descendant_of(child) }
      it { should be_is_ancestor_of(child) }
      it { should be_is_or_is_ancestor_of(child) }

      it { should_not be_is_descendant_of(grandchild) }
      it { should_not be_is_or_is_descendant_of(grandchild) }
      it { should be_is_ancestor_of(grandchild) }
      it { should be_is_or_is_ancestor_of(grandchild) }
    end
  end

  describe "#left_sibling" do
    let(:items) { FactoryGirl.create_list :default, 3 }
    subject { items }

    its('first.left_sibling') { should be_nil }
    specify { items[1].left_sibling.should eq items.first }
  end
end