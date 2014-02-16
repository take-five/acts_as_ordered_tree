# coding: utf-8

shared_examples 'ActsAsOrderedTree adapter' do |adapter_class, model, attrs = {}|
  context model do
    let(:root) { create model, attrs }
    let(:child_1) { create model, attrs.merge(:parent => root) }
    let(:child_2) { create model, attrs.merge(:parent => root) }
    let!(:grandchild_11) { create model, attrs.merge(:parent => child_1) }
    let!(:grandchild_12) { create model, attrs.merge(:parent => child_1) }
    let!(:grandchild_21) { create model, attrs.merge(:parent => child_2) }
    let!(:grandchild_22) { create model, attrs.merge(:parent => child_2) }

    let(:adapter) { adapter_class.new(root.ordered_tree) }

    shared_examples 'ActsAsOrderedTree traverse down for not persisted record' do |method|
      context 'when new record given' do
        let(:record) { build model, attrs.merge(:parent => root) }

        subject(:relation) { adapter.send(method, record) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns empty relation' do
          expect(relation.to_a).to eq []
        end

        it 'does not execute SQL queries' do
          expect{relation.to_a}.not_to query_database
        end
      end

      context 'when destroyed record given' do
        before { child_1.destroy }

        subject(:relation) { adapter.send(method, child_1) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns empty relation' do
          expect(relation.to_a).to eq []
        end

        it 'does not execute SQL queries' do
          expect{relation.to_a}.not_to query_database
        end
      end
    end

    describe '#self_and_descendants' do
      context 'when persisted record given' do
        subject(:relation) { adapter.self_and_descendants(root) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns node and its descendants ordered by position' do
          expect(relation.to_a).to eq Array[
                                          root,
                                          child_1,
                                          grandchild_11,
                                          grandchild_12,
                                          child_2,
                                          grandchild_21,
                                          grandchild_22
                                      ]
        end
      end

      include_examples 'ActsAsOrderedTree traverse down for not persisted record', :self_and_descendants
    end

    describe '#descendants' do
      context 'when persisted record given' do
        subject(:relation) { adapter.descendants(root) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns node and its descendants ordered by position' do
          expect(relation.to_a).to eq Array[
                                          child_1,
                                          grandchild_11,
                                          grandchild_12,
                                          child_2,
                                          grandchild_21,
                                          grandchild_22
                                      ]

          expect(adapter.descendants(child_1)).to eq [grandchild_11, grandchild_12]
        end

        it 'updates descendants' do
          relation.update_all(:name => 'x')
          expect(relation.all? { |r| r.reload.name == 'x' }).to be_true

          adapter.descendants(child_1).update_all(:name => 'y')
          adapter.descendants(child_2).update_all(:name => 'z')

          expect(relation.map { |r| r.reload.name }).to eq ['x', 'y', 'y', 'x', 'z', 'z']
        end
      end

      include_examples 'ActsAsOrderedTree traverse down for not persisted record', :descendants
    end

    describe '#self_and_ancestors' do
      context 'when persisted record given' do
        context 'when level > 0' do
          subject(:relation) { adapter.self_and_ancestors(grandchild_11) }

          it { expect(relation).to be_a ActiveRecord::Relation }

          it 'returns all node ancestors and itself starting from root' do
            expect(relation.to_a).to eq Array[root, child_1, grandchild_11]
          end
        end

        context 'when level = 0' do
          subject(:relation) { adapter.self_and_ancestors(root) }

          it { expect(relation).to be_a ActiveRecord::Relation }

          it { expect(relation.to_a).to eq [root] }

          it 'does not query database' do
            expect{relation.to_a}.not_to query_database
          end
        end
      end

      context 'when new record given' do
        let(:record_grandparent) { build model, attrs.merge(:parent => grandchild_11) }
        let(:record_parent) { build model, attrs.merge(:parent => record_grandparent) }
        let(:record) { build model, attrs.merge(:parent => record_parent) }

        subject(:relation) { adapter.self_and_ancestors(record) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns all node ancestors and itself starting from root' do
          expect(relation.to_a).to eq Array[root, child_1, grandchild_11, record_grandparent, record_parent, record]
        end
      end

      context 'when destroyed record given' do
        before { grandchild_11.destroy }

        subject(:relation) { adapter.self_and_ancestors(grandchild_11) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns all node ancestors and itself starting from root' do
          expect(relation.to_a).to eq Array[root, child_1, grandchild_11]
        end
      end
    end

    describe '#ancestors' do
      context 'when persisted record given' do
        context 'when level > 0' do
          subject(:relation) { adapter.ancestors(grandchild_11) }

          it { expect(relation).to be_a ActiveRecord::Relation }

          it 'returns all node ancestors and itself starting from root' do
            expect(relation.to_a).to eq Array[root, child_1]
          end
        end

        context 'when level = 0' do
          subject(:relation) { adapter.ancestors(root) }

          it { expect(relation).to be_a ActiveRecord::Relation }

          it { expect(relation.to_a).to eq [] }

          it 'does not query database' do
            expect{relation.to_a}.not_to query_database
          end
        end
      end

      context 'when new record given' do
        let(:record_grandparent) { build model, attrs.merge(:parent => grandchild_11) }
        let(:record_parent) { build model, attrs.merge(:parent => record_grandparent) }
        let(:record) { build model, attrs.merge(:parent => record_parent) }

        subject(:relation) { adapter.ancestors(record) }

        it { expect(relation).to be_a ActiveRecord::Relation }

        it 'returns all node ancestors and itself starting from root' do
          expect(relation.to_a).to eq Array[root, child_1, grandchild_11, record_grandparent, record_parent]
        end
      end
    end
  end
end