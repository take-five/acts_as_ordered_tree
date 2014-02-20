require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree, :transactional do
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
    let(:root) { create :default_with_counter_cache }
    before { create_list :default_with_counter_cache, 2, :parent => root }

    subject { DefaultWithCounterCache }

    it { should respond_to(:leaves) }
    its(:leaves) { should have(2).items }
  end

  describe ".root" do
    # create fixture
    let!(:root) { create :default }

    context "given a single root node" do
      subject { root }

      its(:position) { should eq 1 }
    end

    context "given multiple root nodes" do
      before { create_list :default, 3 }

      subject { Default }

      its(:root) { should eq root }
    end
  end

  describe "#level" do
    context "given a persistent root node" do
      subject { create :default }

      its(:level) { should eq 0 }
    end
    context "given a new root record" do
      subject { build :default }

      its(:level) { should eq 0 }
    end
    context "given a persistent node with parent" do
      let(:root) { create :default }
      subject { create :default, :parent => root }
      its(:level) { should eq 1 }
    end
    context "given a new node with parent" do
      let(:root) { create :default }
      subject { build :default, :parent => root }
      its(:level) { should eq 1 }
    end

    context 'a model without depth column' do
      let(:root) { create :scoped }
      subject { create :scoped, :parent => root, :scope_type => root.scope_type }
      its(:level) { should eq 1 }
    end
  end

  describe "#left_sibling" do
    shared_examples "tree with siblings" do
      subject { items }

      its('first.left_sibling') { should be_nil }
      its('first.right_sibling') { should eq items.second }

      its('second.left_sibling') { should eq items.first }
      its('second.right_sibling') { should eq items.last }

      its('third.left_sibling') { should eq items.second }
      its('third.right_sibling') { should be_nil }
    end

    context "given unscoped tree" do
      it_should_behave_like "tree with siblings" do
        let(:items) { create_list :default, 3 }
      end
    end

    context "given scoped tree" do
      let!(:items_1) { create_list :scoped, 3, :scope_type => "s1" }
      let!(:items_2) { create_list :scoped, 3, :scope_type => "s2" }

      it_should_behave_like "tree with siblings" do
        let(:items) { items_1 }
      end
      it_should_behave_like "tree with siblings" do
        let(:items) { items_2 }
      end
    end
  end

  describe "move actions" do
    let!(:root) { create :default_with_counter_cache, :name => 'root' }
    let!(:child_1) { create :default_with_counter_cache, :parent => root, :name => 'child_1' }
    let!(:child_2) { create :default_with_counter_cache, :parent => root, :name => 'child_2' }
    let!(:child_3) { create :default_with_counter_cache, :parent => root, :name => 'child_3' }
    let!(:child_4) { create :default_with_counter_cache, :parent => child_3, :name => 'child_4' }

    describe "#insert_at" do
      before { ActiveSupport::Deprecation.silence { child_3.insert_at(1) } }
      before { child_3.reload }

      specify { expect([child_3, child_1, child_2]).to be_sorted }
    end

    describe "callbacks" do
      subject { child_3 }

      it "should recalculate depth of descendants" do
        record = create :default_with_counter_cache, :parent => child_3
        record.depth.should eq 2

        child_3.reload.depth.should eq 1
        child_1.reload.depth.should eq 1

        child_3.move_to_root
        record.reload.depth.should eq 1

        child_1.reload.depth.should eq 1

        child_3.move_to_child_of child_1
        child_3.reload

        child_3.parent.should eq child_1
        child_3.depth.should eq 2

        record.reload.depth.should eq 3
      end
    end

    context "changed attributes" do
      before do
        child_2.name = 'changed_100'
        child_2.move_to_left_of child_1
      end

      it { child_2.reload.name.should eq 'child_2' }
    end

  end

  describe "scoped trees" do
    let!(:root1) { create :scoped, :scope_type => "t1" }
    let!(:child1) { create :scoped, :parent => root1 }
    let!(:orphan) do
      record = create :scoped, :parent => root1
      record.class.where(:id => record.id).update_all(:scope_type => "t0", :position => 1)
      record
    end

    let!(:root2) { create :scoped, :scope_type => "t2" }
    let!(:child2) { create :scoped, :scope_type => "t2", :parent => root2 }

    it "should not stick positions together for different scopes" do
      root1.position.should eq root2.position
    end
    it "should automatically set scope for new records with parent" do
      child1.ordered_tree_node.should be_same_scope(root1)
    end
    it "should not include orphans" do
      root1.children.reload.should_not include orphan
      root1.descendants.reload.should_not include orphan
    end
    it "should not allow to move records between scopes" do
      expect { child2.move_to_child_of root1 }.to raise_error(ActiveRecord::ActiveRecordError)
    end
    it "should not allow to change scope" do
      child2.parent = root1
      child2.should have_at_least(1).error_on(:parent)
    end
    it "should not allow to add scoped record to children collection" do
      root1.children << child2
      root1.children.reload.should_not include child2
    end
  end

  describe "potential vulnerabilities" do
    describe "attempt to link parent to one of descendants" do
      let(:root) { create :default }
      let(:child) { create :default, :parent => root }
      let(:grandchild) { create :default, :parent => child }

      subject { root }

      context "given self as parent" do
        before { root.parent = root }

        it { should have_at_least(1).error_on(:parent) }
      end

      context "given child as parent" do
        before { root.parent = child }

        it { should have_at_least(1).error_on(:parent) }
      end

      context "given grandchild as parent" do
        before { root.parent = grandchild }

        it { should have_at_least(1).error_on(:parent) }
      end
    end
  end
end
