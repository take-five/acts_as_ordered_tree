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

  describe "#root?, #child?, #leaf? and #root" do
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
        its(:root) { should eq root }
        its(:level) { should eq 0 }
      end

      context "given a branch node with children" do
        subject { child }

        it { should_not be_root }
        it { should be_child }
        it { should_not be_leaf }
        its(:root) { should eq root }
        its(:level) { should eq 1 }
      end

      context "given a leaf node" do
        subject { grandchild }

        it { should_not be_root }
        it { should be_child }
        it { should be_leaf }
        its(:root) { should eq root }
        its(:level) { should eq 2 }
      end

      context "given a new record" do
        subject { build factory_name }

        it { should_not be_leaf }
      end
    end

    it_behaves_like "tree with predicates", :default
    it_behaves_like "tree with predicates", :default_with_counter_cache
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
  end

  describe "#self_and_ancestors" do
    # create fixture
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

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
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

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
    let!(:root) { create :default }
    let!(:child) { create :default, :parent => root }
    let!(:grandchild) { create :default, :parent => child }

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
    let(:items) { create_list :default, 3 }
    subject { items }

    its('first.left_sibling') { should be_nil }
    its('second.left_sibling') { should eq items.first }
    its('third.left_sibling') { should eq items.second }
  end

  describe "#right_sibling" do
    let(:items) { create_list :default, 3 }
    subject { items }

    its('first.right_sibling') { should eq items.second }
    its('second.right_sibling') { should eq items.third }
    its('last.right_sibling') { should be_nil }
  end

  describe "#reload_node" do
    let!(:node) { create :default }

    before do
      node.name = 'changed'
      node.parent_id = 200
      node.position = 1000
    end

    subject { node.send :reload_node }

    its(:name) { should eq 'changed' }
    its(:parent_id) { should be_nil }
    its(:position) { should eq 1 }
  end

  describe "move actions" do
    let!(:root) { create :default, :name => 'root' }
    let!(:child_1) { create :default, :parent => root, :name => 'child_1' }
    let!(:child_2) { create :default, :parent => root, :name => 'child_2' }
    let!(:child_3) { create :default, :parent => root, :name => 'child_3' }

    context "initial" do
      subject { root }

      specify { expect([child_1, child_2, child_3]).to be_sorted }

      its(:parent_id) { should be_nil }
      its(:level) { should be_zero }
      its(:position) { should eq 1 }
    end

    describe "#move_left" do
      example "move_1_left" do
        expect{ child_1.move_left }.to raise_exception ActiveRecord::ActiveRecordError
        expect([child_1, child_2, child_3]).to be_sorted
      end

      example "move_2_left" do
        child_2.move_left
        expect([child_2, child_1, child_3]).to be_sorted
      end

      example "move_3_left" do
        child_3.move_left
        expect([child_1, child_3, child_2]).to be_sorted
      end
    end

    describe "#move_right" do
      example "move_3_right" do
        expect{ child_3.move_right }.to raise_exception ActiveRecord::ActiveRecordError
        expect([child_1, child_2, child_3]).to be_sorted
      end

      example "move_2_right" do
        child_2.move_right
        expect([child_1, child_3, child_2]).to be_sorted
      end

      example "move_1_right" do
        child_1.move_right
        expect([child_2, child_1, child_3]).to be_sorted
      end
    end

    describe "#move_to_left_of" do
      example "move_3_to_left_of_1" do
        child_3.move_to_left_of child_1
        expect([child_3, child_1, child_2]).to be_sorted
      end

      example "move_3_to_left_of_2" do
        child_3.move_to_left_of child_2
        expect([child_1, child_3, child_2]).to be_sorted
      end

      example "move_1_to_left_of_3" do
        child_1.move_to_left_of child_3
        expect([child_2, child_1, child_3]).to be_sorted
      end

      example "move_1_to_left_of_3_id" do
        child_1.move_to_left_of child_3.id
        expect([child_2, child_1, child_3]).to be_sorted
      end

      example "move_root_to_left_of_child_2" do
        expect{ root.move_to_left_of child_2 }.to raise_exception ActiveRecord::ActiveRecordError
      end
    end

    describe "#move_to_right_of" do
      example "move_1_to_right_of_2" do
        child_1.move_to_right_of child_2
        expect([child_2, child_1, child_3]).to be_sorted
      end

      example "move_1_to_right_of_3" do
        child_1.move_to_right_of child_3
        expect([child_2, child_3, child_1]).to be_sorted
      end

      example "move_1_to_right_of_3_id" do
        child_1.move_to_right_of child_3.id
        expect([child_2, child_3, child_1]).to be_sorted
      end

      example "move_3_to_right_of_1" do
        child_3.move_to_right_of child_1
        expect([child_1, child_3, child_2]).to be_sorted
      end

      example "move_root_to_right_of_child_2" do
        expect{ root.move_to_right_of child_2 }.to raise_exception ActiveRecord::ActiveRecordError
      end
    end

    describe "#move_to_root" do
      before { child_2.move_to_root }

      context "child_2" do
        subject { child_2 }

        its(:level) { should be_zero }
        its(:parent_id) { should be_nil }
        its(:position) { should eq 2 }

        it "should not become new root" do
          Default.root.should eq root
        end
      end

      context "other_children" do
        specify { child_1.reload.position.should eq 1 }
        specify { child_3.reload.position.should eq 2 }
      end

      context "given a root node" do
        before { root.move_to_root }
        subject { root }

        its(:position) { should eq 1 }

        it "positions should not change" do
          expect([root, child_3]).to be_sorted
        end
      end
    end

    describe "#move_to_child_of" do
      let(:moved_child) { create :default, :name => 'moved_child' }

      before { moved_child.move_to_child_of root }
      context "moved_child" do
        subject { moved_child }
        its(:level) { should eq 1 }
        its(:position) { should eq 4 }
      end

      context "root" do
        subject { root }
        its(:right_sibling) { should be_nil }
      end

      it { expect([child_1, child_2, child_3, moved_child]).to be_sorted }
      it { expect{ root.move_to_child_of root }.to raise_exception ActiveRecord::ActiveRecordError }
      it { expect{ root.move_to_child_of child_1 }.to raise_exception ActiveRecord::ActiveRecordError }
    end

    describe "#move_to_child_with_index" do
      let(:moved_child) { create :default, :name => 'moved_child' }

      example "move_to_child_as_first" do
        moved_child.move_to_child_with_index root, 0
        expect([moved_child, child_1, child_2, child_3]).to be_sorted
        moved_child.position.should eq 1
      end

      example "move_to_child_as_second" do
        moved_child.move_to_child_with_index root, 1
        expect([child_1, moved_child, child_2, child_3]).to be_sorted
        moved_child.position.should eq 2
      end

      example "move_to_child_as_third" do
        moved_child.move_to_child_with_index root, 2
        expect([child_1, child_2, moved_child, child_3]).to be_sorted
        moved_child.position.should eq 3
      end

      example "move_to_child_as_last" do
        moved_child.move_to_child_with_index root, 3
        expect([child_1, child_2, child_3, moved_child]).to be_sorted
        moved_child.position.should eq 4
      end

      example "move_child_to_root_as_first" do
        child_3.move_to_child_with_index nil, 0
        child_3.level.should be_zero
        expect([child_3, root, moved_child]).to be_sorted
        expect([child_1, child_2]).to be_sorted
        child_2.right_sibling.should be_nil
      end

      example "move_to_child_with_large_index" do
        moved_child.move_to_child_with_index root, 100
        expect([child_1, child_2, child_3, moved_child]).to be_sorted
        moved_child.position.should eq 4
      end

      example "move_to_child_with_negative_index" do
        moved_child.move_to_child_with_index root, -2
        expect([child_1, child_2, moved_child, child_3]).to be_sorted
        moved_child.position.should eq 3
      end

      example "move_to_child_with_large_negative_index" do
        expect{ moved_child.move_to_child_with_index root, -100 }.to raise_exception ActiveRecord::ActiveRecordError
      end

      example "move_to_child_with_nil_index" do
        expect{ moved_child.move_to_child_with_index root, nil }.to raise_exception ActiveRecord::ActiveRecordError
      end

      example "move_to_child_with_float_index" do
        moved_child.move_to_child_with_index root, 1.7
        expect([child_1, moved_child, child_2, child_3]).to be_sorted
      end

      example "move_root_to_child_of_self" do
        expect{ root.move_to_child_with_index child_1, 1 }.to raise_exception ActiveRecord::ActiveRecordError
      end

    end

    describe "callbacks" do
      subject { child_3 }

      it { should fire_callback(:before_move).when_calling(:move_to_root).once }
      it { should fire_callback(:after_move).when_calling(:move_to_root).once }
      it { should fire_callback(:around_move).when_calling(:move_to_root).once }

      it { should_not fire_callback(:before_move).when_calling(:move_left) }
      it { should_not fire_callback(:after_move).when_calling(:move_left) }
      it { should_not fire_callback(:around_move).when_calling(:move_left) }

      it "should cache depth on save" do
        record = build :default

        record.depth.should be_nil
        record.save

        record.depth.should eq 0

        record.move_to_left_of child_3
        record.depth.should eq child_3.level
      end
    end

  end

  describe "scoped trees" do
    let!(:root1) { create :scoped, :scope_type => "t1" }
    let!(:child1) { create :scoped, :parent => root1 }
    let!(:orphan) do
      record = create :scoped, :parent => root1
      record.class.update_all({:scope_type => "t0", :position => 1}, {:id => record.id})
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

  describe "#destroy behavior" do
    let!(:root) { create :default, :name => 'root' }
    let!(:child_1) { create :default, :parent => root, :name => 'child_1' }
    let!(:child_2) { create :default, :parent => root, :name => 'child_2' }
    let!(:child_3) { create :default, :parent => root, :name => 'child_3' }

    describe "it should destroy descendants" do
      subject { root }
      before { subject.destroy }

      it { should be_destroyed }
      its('descendants.reload') { should be_empty }

      specify "ensure the loneliness" do
        root.class.all.should be_empty
      end
    end

    describe "it should stick positions together" do
      before { child_2.destroy }
      before { child_3.reload }

      subject { child_3 }

      its(:left_sibling) { should eq child_1 }
      its(:position) { should eq 2 }
    end
  end

  describe "vulnerabilities" do
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