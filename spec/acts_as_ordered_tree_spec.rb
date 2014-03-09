require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree, :transactional do
  it "creation_with_altered_column_names" do
    lambda {
      RenamedColumns.create!()
    }.should_not raise_exception
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
      before { child_2.name = 'changed_100' }

      it { expect{child_2.move_to_left_of(child_1)}.to change(child_2, :name).to('child_2') }
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
      expect(root1.children.reload).not_to include orphan
      expect(root1.descendants.reload).not_to include orphan
    end
    it "should not allow to move records between scopes" do
      expect(child2.move_to_child_of(root1)).to be_false
      expect(child2).to have_at_least(1).error_on(:parent)
    end
    it "should not allow to change scope" do
      child2.parent = root1
      expect(child2).to have_at_least(1).error_on(:parent)
    end
    it "should not allow to add scoped record to children collection" do
      root1.children << child2
      expect(root1.children.reload).not_to include child2
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
