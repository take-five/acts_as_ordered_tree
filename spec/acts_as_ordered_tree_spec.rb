require File.expand_path('../spec_helper', __FILE__)

describe ActsAsOrderedTree, :transactional do
  example 'creation_with_altered_column_names' do
    expect{RenamedColumns.create!}.not_to raise_error
  end

  describe '#level' do
    context 'given a persistent root node' do
      subject { create :default }

      its(:level) { should eq 0 }
    end

    context 'given a new root record' do
      subject { build :default }

      its(:level) { should eq 0 }
    end

    context 'given a persistent node with parent' do
      let(:root) { create :default }
      subject { create :default, :parent => root }
      its(:level) { should eq 1 }
    end

    context 'given a new node with parent' do
      let(:root) { create :default }
      subject { build :default, :parent => root }
      its(:level) { should eq 1 }
    end

    context 'a model without depth column' do
      tree :factory => :scoped do
        root {
          child {
            grandchild
          }
        }
      end

      before { root.reload }
      before { child.reload }
      before { grandchild.reload }

      it { expect(root.level).to eq 0 }
      it { expect{root.level}.not_to query_database }

      it { expect(child.level).to eq 1 }
      it { expect{child.level}.to query_database.once }

      it { expect(grandchild.level).to eq 2 }
      it { expect{grandchild.level}.to query_database.at_least(:once) }

      context 'given a record with already loaded parent' do
        before { child.association(:parent).load_target }
        before { grandchild.parent.association(:parent).load_target }

        it { expect(child.level).to eq 1 }
        it { expect{child.level}.not_to query_database }

        it { expect(grandchild.level).to eq 2 }
        it { expect{grandchild.level}.not_to query_database }
      end
    end
  end

  describe 'move actions' do
    tree :factory => :default_with_counter_cache do
      root {
        child_1
        child_2 :name => 'child_2'
        child_3 {
          child_4
        }
      }
    end

    describe '#insert_at' do
      before { ActiveSupport::Deprecation.silence { child_3.insert_at(1) } }
      before { child_3.reload }

      specify { expect([child_3, child_1, child_2]).to be_sorted }
    end
  end

  describe 'scoped trees' do
    tree :factory => :scoped do
      root1 :scope_type => 't1' do
        child1
        orphan
      end
      root2 :scope_type => 't2' do
        child2
      end
    end

    before { Scoped.where(:id => orphan.id).update_all(:scope_type => 't0', :position => 1) }

    it 'should not stick positions together for different scopes' do
      expect(root1.position).to eq root2.position
    end
    it 'should automatically set scope for new records with parent' do
      expect(child1.ordered_tree_node).to be_same_scope root1
    end
    it 'should not include orphans' do
      expect(root1.children.reload).not_to include orphan
      expect(root1.descendants.reload).not_to include orphan
    end
    it 'should not allow to move records between scopes' do
      expect(child2.move_to_child_of(root1)).to be_false
      expect(child2).to have_at_least(1).error_on(:parent)
    end
    it 'should not allow to change scope' do
      child2.parent = root1
      expect(child2).to have_at_least(1).error_on(:parent)
    end
    it 'should not allow to add scoped record to children collection' do
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
