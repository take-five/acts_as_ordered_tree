require File.expand_path('../test_helper', __FILE__)

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
    it "should be properly configured" do
      Node.position_column.should eq(:position)
      Node.parent_column.should eq(:parent_id)
    end

    it "should have roots" do
      Node.roots.count.should eq(1)
      Node.roots.first.should eq(root)
      Node.root.should eq(root)
    end
  end

  describe "tree" do
    it "should have roots" do
      root.root.should eq(root)
      branch.root.should eq(root)
      leaf.root.should eq(root)
    end

    it "should have children" do
      root.children.count.should eq(2)
      branch.children.count.should eq(2)
      leaf.children.count.should eq(0)
    end

    it "should have parents" do
      root.parent.should be(nil)
      branch.parent.should eq(root)
      leaf.parent.should eq(branch)
    end

    it "should return true if root" do
      root.root?.should be(true)
      branch.root?.should be(false)
      leaf.root?.should be(false)
    end

    it "should return true if leaf" do
      root.leaf?.should be(false)
      branch.leaf?.should be(false)
      leaf.leaf?.should be(true)
    end

    it "should tell about node's depth" do
      root.depth.should eq(0)
      branch.depth.should eq(1)
      leaf.depth.should eq(2)
    end

    it "should iterate over ancestors" do
      leaf.ancestors.should have(2).items
      branch.ancestors.should have(1).items
      root.ancestors.should have(0).items
    end

    it "should iterate over descendants" do
      root.descendants.should have(5).items
      root.descendants.first.should eq(branch)
      root.descendants.last.should eq(last)

      branch.descendants.should have(2).items
      branch.descendants.first.should eq(leaf)

      leaf.descendants.should have(0).items
    end

    it "should have siblings" do
      branch.self_and_siblings.should have(2).items
      branch.self_and_siblings.should include(branch)

      branch.siblings.should have(1).item
      branch.siblings.should_not include(branch)
    end
  end

  describe "list" do
    it "should be ordered" do
      root.position.should eq(1)
      root.children.first.position.should eq(1)
      root.children.last.position.should eq(2)
    end

    it "should be sortable through scope" do
      Node.where(:parent_id => root.id).ordered.first.should eq(branch)
    end
  end

  describe "mutations" do
    around(:each) do |example|
      Node.transaction do
        example.run

        raise ActiveRecord::Rollback
      end
    end

    it "should be placed to the bottom of the list" do
      blank.save
      branch.children.last.should eq(blank)
    end

    it "should be placed to the middle of the list" do
      blank.position = 2
      blank.save

      blank.position.should eq(2)
      blank.siblings.should have(2).items
      blank.siblings.last.position.should eq(3)
    end

    it "should be movable inside parent" do
      last_child = branch.children.last

      blank.save
      blank.move_higher

      blank.position.should eq(2)
      last_child.reload.position.should eq(3)

      blank.move_lower
      blank.position.should eq(3)
    end

    it "should be movable to bottom of its parent" do
      first_child = branch.children.first

      first_child.move_to_bottom
      first_child.position.should eq(2)
      first_child.reload.position.should eq(2)
    end

    it "should be movable to top of its parent" do
      first_child = branch.children.first
      last_child = branch.children.last

      last_child.move_to_top

      last_child.position.should eq(1)
      last_child.reload.position.should eq(1)

      first_child.reload.position.should eq(2)
    end

    it "should shift up lower items when parent is changed" do
      first_child = branch.children.first
      last_child = branch.children.last
      
      # move to other parent
      first_child.parent = second_branch
      first_child.should be_parent_changed

      first_child.save

      # old sibling should shift up
      last_child.reload.position.should eq(1)
    end

    it "should save its previous position when parent is changed" do
      first_child = branch.children.first

      first_child.parent = second_branch
      first_child.save

      first_child.position.should eq(1)
      last.position.should eq(2)
    end

    it "should be movable to last position of new parent" do
      first_child = branch.children.first

      first_child.move_to_child_of(second_branch)
      first_child.parent.should eq(second_branch)
      first_child.should be_last
    end

    it "should be movable to above of some node" do
      first_child = branch.children.first
      above_of    = second_branch.children.first

      first_child.move_to_above_of(above_of)
      first_child.parent.should eq(second_branch)
      
      first_child.position.should eq(1)
      above_of.position.should eq(2)
    end

    it "should be movable to bottom of some node" do
      second = second_branch

      first_child = branch.children.first

      first_child.move_to_bottom_of(branch)
      first_child.parent.should eq(branch.parent)

      first_child.position.should eq(2)
      second.reload.position.should eq(3)
    end

    it "should shift up lower items on destroy" do
      branch.children.first.destroy

      branch.children.should have(1).items
      branch.children.first.position.should eq(1)
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
end