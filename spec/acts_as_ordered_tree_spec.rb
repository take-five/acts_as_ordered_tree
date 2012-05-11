require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree do
  before :all do
    root   = Node.create(:name => "Root")
    child1 = Node.create(:parent_id => root.id, :name => "Child 1")
    child2 = Node.create(:parent_id => root.id, :name => "Child 2")

    Node.create(:parent_id => child1.id, :name => "Subchild 1")
    Node.create(:parent_id => child1.id, :name => "Subchild 2")
    Node.create(:parent_id => child2.id, :name => "Subchild 3")
  end

  let(:root) { Node.where(:parent_id => nil).first }
  let(:branch) { Node.where(:parent_id => root.id).first }
  let(:second_branch) { Node.where(:parent_id => root.id).last }
  let(:leaf) { Node.where(:parent_id => branch.id).first }
  let(:last) { Node.last }
  let(:blank) { Node.new(:parent_id => branch.id) }

  describe "class" do
    subject { Node }

    its(:position_column) { should eq :position }
    its(:parent_column) { should eq :parent_id }

    its(:roots) { should have(1).item }
    its('roots.first') { should eq root }
    its(:root) { should eq root }
  end

  describe "Root" do
    subject { root }

    its(:root) { should eq root }
    its(:children) { should have(2).items }
    its(:parent) { should be_nil }

    it { should be_root }
    it { should_not be_leaf }

    its(:depth) { should eq 0 }
    its(:position) { should eq 1 }
    its('children.first.position') { should eq 1 }
    its('children.last.position') { should eq 2 }

    its(:ancestors) { should have(0).items }
    its(:self_and_descendants) { should have(6).items }

    its(:descendants) { should have(5).items }
    its('descendants.first') { should eq branch }
    its('descendants.last') { should eq last }
  end

  describe "Branch" do
    subject { branch }

    its(:root) { should eq root }
    its(:children) { should have(2).items }
    its(:parent) { should eq root }
    it { should_not be_root }
    it { should_not be_leaf }

    its(:depth) { should eq 1 }
    its(:position) { should eq 1 }

    its(:ancestors) { should have(1).item }

    its(:descendants) { should have(2).items }
    its('descendants.first') { should eq leaf }

    its(:self_and_siblings) { should have(2).items }
    its(:self_and_siblings) { should include branch }

    its(:siblings) { should have(1).item }
    its(:siblings) { should_not include branch }
  end

  describe "Leaf" do
    subject { leaf }

    its(:root) { should eq root }
    its(:children) { should be_empty }
    its(:parent) { should eq branch }
    it { should_not be_root }
    it { should be_leaf }
    its(:depth) { should eq 2 }

    its(:self_and_ancestors) { should have(3).items }
    its(:ancestors) { should have(2).items }
    its('ancestors.first') { should eq branch }
    its('ancestors.last') { should eq root }

    its(:descendants) { should be_empty }
    its(:siblings) { should have(1).item }
  end

  describe "Scope" do
    subject { root.children.ordered }

    it { should be_a ActiveRecord::Relation }
    its(:order_values) { should include Node.position_column }
  end

  describe "mutations" do
    around(:each) do |example|
      Node.transaction do
        example.run

        raise ActiveRecord::Rollback
      end
    end

    context "Insertion of a new node at the end of list (by default)" do
      subject { blank }

      before { subject.save }

      it { should be_persisted }
      its(:parent) { should eq branch }
      it { should be_last }
    end

    describe "Insertion of a new node at certain position" do
      subject { blank }

      before { subject.position = 2 }
      before { subject.save }

      it { should be_persisted }
      its(:position) { should eq 2 }
      it { should_not be_last }
      it { should_not be_first }

      its(:siblings) { should have(2).items }
    end

    describe "Moving a node inside parent's children" do
      let(:last_child) { branch.children.last }

      subject { blank }

      before { subject.save }

      describe "#move_higher" do
        before { subject.move_higher }

        its(:position) { should eq 2 }
        its(:lower_item) { should eq last_child }
      end

      describe "#move_lower" do
        before { subject.move_higher }
        before { subject.move_lower }

        its(:position) { should eq 3 }
        it { should be_last }
      end

      describe "#move_to_top" do
        before { subject.move_to_top }

        it { should be_first }
      end

      describe "#move_to_bottom" do
        before { subject.move_to_top }
        before { subject.move_to_bottom }

        it { should be_last }
      end
    end

    describe "Changing node's parent" do
      subject { branch.children.first }

      let!(:sibling) { subject.siblings.first }

      before { subject.parent = second_branch }
      before { subject.save }

      it "should shift up lower items" do
        sibling.reload.position.should eq 1
      end

      it "should save its previous position" do
        subject.position.should eq 1
      end
    end

    describe "Moving node between different parents" do
      subject { branch.children.last }

      describe "#move_to_child_of" do
        before { subject.move_to_child_of second_branch }
        before { subject.reload }

        its(:parent) { should eq second_branch }
        it { should be_last }
      end

      describe "#move_to_above_of" do
        let!(:above_of) { second_branch.children.first }

        before { subject.move_to_above_of above_of }

        its(:parent) { should eq second_branch }
        its(:position) { should eq 1 }

        it "should shift down +above_of+ node" do
          above_of.position.should eq 2
        end
      end

      describe "#move_to_bottom_of" do
        before { subject.move_to_bottom_of branch }

        its(:parent) { should eq branch.parent }
        its(:position) { should eq 2 }
      end
    end

    describe "Destroying node" do
      subject { branch.children }

      before { subject.first.destroy }

      it { should have(1).item }
      its('first.position') { should eq 1 }
    end


    describe "validations" do
      it "should not allow to link parent to itself" do
        branch.parent = branch
        branch.should_not be_valid
      end

      it "should not allow to link to one of its descendants" do
        branch.parent = leaf
        branch.should_not be_valid
      end
    end


    describe "callbacks" do
      it "should fire *_reorder callbacks when position (but not parent) changes" do
        examples_count = 6

        second_branch.should_receive(:on_before_reorder).exactly(examples_count)
        second_branch.should_receive(:on_around_reorder).exactly(examples_count)
        second_branch.should_receive(:on_after_reorder).exactly(examples_count)

        second_branch.move_higher
        second_branch.move_lower
        second_branch.move_to_top
        second_branch.move_to_bottom
        second_branch.decrement_position
        second_branch.increment_position
      end

      it "should not fire *_reorder callbacks when parent_changes" do
        leaf.should_not_receive(:on_before_reorder)
        leaf.should_not_receive(:on_around_reorder)
        leaf.should_not_receive(:on_after_reorder)

        p1 = leaf.parent
        p2 = second_branch

        leaf.move_to_child_of(p2)
        leaf.move_to_above_of(p1.children.first)
        leaf.move_to_child_of(p2)
        leaf.move_to_bottom_of(p1.children.first)
      end

      it "should not fire *_reorder callbacks when position is not changed" do
        leaf.should_not_receive(:on_before_reorder)
        leaf.should_not_receive(:on_around_reorder)
        leaf.should_not_receive(:on_after_reorder)

        last.should_not_receive(:on_before_reorder)
        last.should_not_receive(:on_around_reorder)
        last.should_not_receive(:on_after_reorder)

        leaf.move_higher
        last.move_lower

        leaf.save
        last.save
      end

      it "should fire *_move callbacks when parent is changed" do
        examples_count = 3
        leaf.should_receive(:on_before_move).exactly(examples_count)
        leaf.should_receive(:on_after_move).exactly(examples_count)
        leaf.should_receive(:on_around_move).exactly(examples_count)

        p1 = leaf.parent
        p2 = second_branch

        leaf.move_to_child_of(p2)
        leaf.move_to_above_of(p1)
        leaf.move_to_bottom_of(p1.children.first)
      end

      it "should not fire *_move callbacks when parent is not changed" do
        leaf.should_not_receive(:on_before_move)
        leaf.should_not_receive(:on_after_move)
        leaf.should_not_receive(:on_around_move)

        leaf.move_to_child_of(leaf.parent)
        leaf.move_to_above_of(leaf.siblings.first)
        leaf.move_to_bottom_of(leaf.siblings.first)
        leaf.reload.save
      end
    end
  end
end