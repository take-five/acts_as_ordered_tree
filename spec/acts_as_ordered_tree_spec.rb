require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree, :transactional do
  describe "defaults" do
    subject { Default }

    its(:parent_column) { should eq :parent_id }
    its(:position_column) { should eq :position }
    its(:depth_column) { should eq :depth }
    its(:children_counter_cache_column) { be_nil }

    if ActsAsOrderedTree::PROTECTED_ATTRIBUTES_SUPPORTED
      context "instance" do
        subject { Default.new }

        it { should_not allow_mass_assignment_of(:position) }
        it { should_not allow_mass_assignment_of(:depth) }
      end
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

    if ActsAsOrderedTree::PROTECTED_ATTRIBUTES_SUPPORTED
      context "instance" do
        subject { RenamedColumns.new }

        it { should_not allow_mass_assignment_of(:red) }
        it { should_not allow_mass_assignment_of(:pitch) }
      end
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

  describe "#root?, #child?, #leaf?, #branch? and #root" do
    shared_examples "tree with predicates" do |factory_name|
      # create fixture
      let!(:root) { create factory_name }
      let!(:child) { create factory_name, :parent => root }
      let!(:grandchild) { create factory_name, :parent => child }

      before { root.reload }
      before { child.reload }
      before { grandchild.reload }

      context "given root node" do
        subject { root }

        it { should be_root }
        it { should_not be_child }
        it { should_not be_leaf }
        it { should be_branch }
        its(:root) { should eq root }
        its(:level) { should eq 0 }
      end

      context "given a branch node with children" do
        subject { child }

        it { should_not be_root }
        it { should be_child }
        it { should_not be_leaf }
        it { should be_branch }
        its(:root) { should eq root }
        its(:level) { should eq 1 }
      end

      context "given a leaf node" do
        subject { grandchild }

        it { should_not be_root }
        it { should be_child }
        it { should be_leaf }
        it { should_not be_branch }
        its(:root) { should eq root }
        its(:level) { should eq 2 }
      end

      context "given a new record" do
        subject { build factory_name }

        it { should_not be_leaf }
        it { should be_branch }
      end
    end

    it_behaves_like "tree with predicates", :default
    it_behaves_like "tree with predicates", :default_with_counter_cache
  end

  describe "#first?, #last?" do
    let!(:root)    { create :default }
    let!(:child_1) { create :default, :parent => root }
    let!(:child_2) { create :default, :parent => root }
    let!(:child_3) { create :default, :parent => root }

    context "given a node without siblings" do
      subject { root }

      it { should be_first }
      it { should be_last }
    end

    context "given a node, first in the list" do
      subject { child_1 }

      it { should be_first }
      it { should_not be_last }
    end

    context "given a node, nor first neither last" do
      subject { child_2 }

      it { should_not be_first }
      it { should_not be_last }
    end

    context "given a node, last in the list" do
      subject { child_3 }

      it { should_not be_first }
      it { should be_last }
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

  describe "#self_and_ancestors" do
    # create fixture
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

    context "leaf" do
      subject { grandchild.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should have(3).items }
      its(:first) { should eq root }
      its(:last) { should eq grandchild }
    end

    context "child" do
      subject { child.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should have(2).items }
      its(:first) { should eq root }
      its(:last) { should eq child }
    end

    context "root" do
      subject { root.self_and_ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should have(1).item }
      its(:first) { should eq root }
    end

    context "when record is new" do
      let(:record) { build(:default, :parent => grandchild) }
      subject { record.self_and_ancestors }

      it { should have(4).items }
      it { should include root }
      it { should include child }
      it { should include grandchild }
      it { should include record }
    end

    context "when parent is changed" do
      before { grandchild.parent = root }
      subject { grandchild.self_and_ancestors }

      it { should include root }
      it { should_not include child }
      it { should include grandchild }
    end
  end

  describe "#ancestors" do
    # create fixture
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

    context "leaf" do
      subject { grandchild.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should have(2).items }
      its(:first) { should eq root }
      its(:last) { should eq child }
    end

    context "child" do
      subject { child.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should have(1).item }
      its(:first) { should eq root }
    end

    context "root" do
      subject { root.ancestors }

      it { should be_a ActiveRecord::Relation }
      it { should be_empty }
    end
  end

  describe "#self_and_descendants" do
    # create fixture
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

    context "leaf" do
      subject { grandchild.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should have(1).item }
      its(:first) { should eq grandchild }
    end

    context "child" do
      subject { child.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should have(2).items }
      its(:first) { should eq child }
      its(:last) { should eq grandchild }
    end

    context "root" do
      subject { root.self_and_descendants }

      it { should be_a ActiveRecord::Relation }
      it { should have(3).items }
      its(:first) { should eq root }
      its(:last) { should eq grandchild }
    end
  end

  describe "#is_descendant_of?, #is_or_is_descendant_of?, #is_ancestor_of?, #is_or_is_ancestor_of?" do
    # create fixture
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

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

    context "initial" do
      specify { expect([child_1, child_2, child_3]).to be_sorted }

      subject { root.reload }
      its(:parent_id) { should be_nil }
      its(:level) { should be_zero }
      its(:position) { should eq 1 }
      its(:categories_count) { should eq 3}
    end

    describe "#insert_at" do
      before { child_3.insert_at(1) }
      before { child_3.reload }

      specify { expect([child_3, child_1, child_2]).to be_sorted }
    end

    describe "callbacks" do
      subject { child_3 }

      it { should fire_callback(:before_move).when_calling(:move_to_root).once }
      it { should fire_callback(:after_move).when_calling(:move_to_root).once }
      it { should fire_callback(:around_move).when_calling(:move_to_root).once }

      it { should_not fire_callback(:before_move).when_calling(:move_left) }
      it { should_not fire_callback(:after_move).when_calling(:move_left) }
      it { should_not fire_callback(:around_move).when_calling(:move_left) }

      it { should fire_callback(:before_reorder).when_calling(:move_higher).once }
      it { should fire_callback(:after_reorder).when_calling(:move_higher).once }

      it { should_not fire_callback(:before_reorder).when_calling(:move_to_root) }

      it "should cache depth on save" do
        record = build :default_with_counter_cache

        record.depth.should be_nil
        record.save

        record.depth.should eq 0

        record.move_to_left_of child_3
        record.depth.should eq child_3.level
      end

      it "should recalculate depth of descendants" do
        record = create :default_with_counter_cache, :parent => child_3
        record.depth.should eq 2

        child_3.move_to_root
        record.reload.depth.should eq 1

        child_3.move_to_child_of child_1
        record.reload.depth.should eq 3
      end

      context "DefaultWithCallbacks" do
        let!(:cb_root_1) { create :default_with_callbacks, :name => 'root_1' }
        let!(:cb_root_2) { create :default_with_callbacks, :name => 'root_2' }
        let!(:cb_child_1) { create :default_with_callbacks, :name => 'child_1', :parent => cb_root_1 }
        let!(:cb_child_2) { create :default_with_callbacks, :name => 'child_2', :parent => cb_root_1 }

        specify "new parent_id should be available in before_move" do
          cb_root_2.stub(:before_move) { cb_root_2.parent_id.should eq cb_root_1.id }
          cb_root_2.move_to_left_of cb_child_1
        end

        specify "new position should be available in before_reorder" do
          cb_child_2.stub(:before_reorder) { cb_child_2.position.should eq 1 }
          cb_child_2.move_to_left_of cb_child_1
        end
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
      child1.should be_same_scope(root1)
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

    describe "attempt to create node with wrong position" do
      it "should not throw error" do
        expect{ create :default, :position => 22 }.not_to raise_error
      end

      it "should be saved at proper position" do
        root = create :default

        node = create :default, :position => 2
        node.position.should eq 2
      end
    end
  end
end
