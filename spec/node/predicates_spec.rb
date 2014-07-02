# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Predicates, :transactional do
  shared_examples 'ActsAsOrderedTree::Node predicates' do |model, attrs = {}|
    describe model do
      let!(:root) { create model, attrs }
      let!(:child) { create model, attrs.merge(:parent => root) }
      let!(:grandchild) { create model, attrs.merge(:parent => child) }

      let(:counter_cached?) { root.class.ordered_tree.columns.counter_cache? }

      before { [root, child, grandchild].each(&:reload) }

      describe '#root?' do
        it { expect(root).to be_root }
        it { expect(child).not_to be_root }
        it { expect(grandchild).not_to be_root }

        it { expect{root.root?}.not_to query_database }
        it { expect{child.root?}.not_to query_database }
        it { expect{grandchild.root?}.not_to query_database }
      end

      describe '#has_parent?' do
        it { expect(root).not_to have_parent }
        it { expect(child).to have_parent }
        it { expect(grandchild).to have_parent }

        it { expect{root.has_parent?}.not_to query_database }
        it { expect{child.has_parent?}.not_to query_database }
        it { expect{grandchild.has_parent?}.not_to query_database }

        it 'should be aliased but deprecated as #child?' do
          expect(ActiveSupport::Deprecation).to receive(:warn)
          expect(root).to receive(:has_parent?)
          ActiveSupport::Deprecation.silence{root.child?}
        end
      end

      describe '#leaf?' do
        it { expect(root).not_to be_leaf }
        it { expect(child).not_to be_leaf }
        it { expect(grandchild).to be_leaf }

        context 'when new record given' do
          let(:record) { build model, attrs }

          it { expect(record).not_to be_leaf }
          it { expect{record.leaf?}.not_to query_database }
        end

        context 'when :children association is loaded' do
          before { root.children << build(model, attrs) }
          before { root.children.reload }

          it { expect(root).not_to be_leaf }
          it { expect{root.leaf?}.not_to query_database }
        end

        context 'when :children association is not loaded' do
          before { root.children << build(model, attrs) }
          before { root.reload }

          it { expect(root).not_to be_leaf }
          it do
            if counter_cached?
              expect{root.leaf?}.not_to query_database
            else
              # we must check that #leaf? is optimized
              expect{root.leaf?}.not_to query_database(/COUNT/)
              expect{root.leaf?}.to query_database(/LIMIT 1/i)
            end
          end
        end
      end

      describe '#has_children?' do
        # opposite of #leaf?
        it { expect(root).to have_children }
        it { expect(child).to have_children }
        it { expect(grandchild).not_to have_children }

        it 'should be aliased but deprecated as #branch?' do
          expect(ActiveSupport::Deprecation).to receive(:warn)
          expect(root).to receive(:has_children?)
          ActiveSupport::Deprecation.silence{root.branch?}
        end
      end

      describe '#is_descendant_of?' do
        it { expect(root) }
      end

      describe '#is_(or_is)_(descendant|ancestor)_of?' do
        matrix3d = Hash[
            :is_descendant_of? => Hash[
                :root => {:root => false, :child => false, :grandchild => false},
                :child => {:root => true, :child => false, :grandchild => false},
                :grandchild => {:root => true, :child => true, :grandchild => false}
            ],
            :is_or_is_descendant_of? => Hash[
                :root => {:root => true, :child => false, :grandchild => false},
                :child => {:root => true, :child => true, :grandchild => false},
                :grandchild => {:root => true, :child => true, :grandchild => true}
            ],
            :is_ancestor_of? => Hash[
                :root => {:root => false, :child => true, :grandchild => true},
                :child => {:root => false, :child => false, :grandchild => true},
                :grandchild => {:root => false, :child => false, :grandchild => false}
            ],
            :is_or_is_ancestor_of? => Hash[
                :root => {:root => true, :child => true, :grandchild => true},
                :child => {:root => false, :child => true, :grandchild => true},
                :grandchild => {:root => false, :child => false, :grandchild => true}
            ]
        ]

        matrix3d.each do |method, matrix|
          matrix.each do |node, examples|
            examples.each do |target, expectation|
              it "expect that #{node}.#{method}(#{target}) == #{expectation.inspect}" do
                expect(send(node).send(method, send(target))).to eq expectation
              end
            end
          end
        end

      end
    end

    describe model do
      let!(:list) { create_list model, 3, attrs }
      let(:first) { list[0] }
      let(:second) { list[1] }
      let(:third) { list[2] }

      describe '#first?' do
        it { expect(first).to be_first }
        it { expect(second).not_to be_first }
        it { expect(third).not_to be_first }

        it 'does not query database' do
          list.each do |node|
            expect{node.first?}.not_to query_database
          end
        end
      end

      describe '#last?' do
        it { expect(first).not_to be_last }
        it { expect(second).not_to be_last }
        it { expect(third).to be_last }

        it { expect{first.last?}.to query_database(/LIMIT 1/i).once }
      end
    end
  end

  include_examples 'ActsAsOrderedTree::Node predicates', :default
  include_examples 'ActsAsOrderedTree::Node predicates', :default_with_counter_cache do
    describe '#last?' do
      context 'when node is child' do
        let(:root) { create :default_with_counter_cache }
        let!(:node) { create :default_with_counter_cache, :parent => root }

        context 'when parent is loaded' do
          before { node.association(:parent).reload }

          it { expect(node).to be_last }
          it { expect{node.last?}.not_to query_database }
        end

        context 'when parent is not loaded' do
          before { node.reload }
          it { expect(node).to be_last }
          it { expect{node.last?}.to query_database.once }
        end
      end
    end
  end

  include_examples 'ActsAsOrderedTree::Node predicates', :scoped, :scope_type => 's' do
    describe '#is_(or_is)_(descendant|ancestor)_of?' do
      context 'when nodes belong to different scopes' do
        let(:root) { create :scoped, :scope_type => 'a' }
        let(:child) { create :scoped, :parent => root }
        # hack it
        before { child.scope_type = 'b' }
        before { child.class.where(:id => child.id).update_all(['scope_type = ?', 'b']) }

        context 'when parent association is cached and cache is stale' do
          it { expect(root.is_ancestor_of?(child)).to be false }
          it { expect(root.is_or_is_ancestor_of?(child)).to be false }
          it { expect(child.is_descendant_of?(root)).to be false }
          it { expect(child.is_or_is_descendant_of?(root)).to be false }
        end

        context 'when parent association is not loaded' do
          before { child.reload }

          it { expect(root.is_ancestor_of?(child)).to be false }
          it { expect(root.is_or_is_ancestor_of?(child)).to be false }
          it { expect(child.is_descendant_of?(root)).to be false }
          it { expect(child.is_or_is_descendant_of?(root)).to be false }
        end
      end
    end
  end
end