# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, '#move_to_child_of', :transactional do
  shared_examples '#move_to_child_of' do |factory|
    describe "#move_to_child_of #{factory}" do
      tree :factory => factory do
        root {
          child_1
          child_2
          child_3 {
            child_4
          }
        }
      end

      context 'when AR object given' do
        it 'moves node' do
          expect {
            child_3.move_to_child_of(child_1)
          }.to change(child_3, :parent).from(root).to(child_1)
        end

        context 'moving to child of self' do
          it { expect(child_3.move_to_child_of(child_3)).to be_false }

          it 'does not move node' do
            expect {
              child_3.move_to_child_of(child_3)
            }.not_to change(child_3, :reload)
          end

          it 'invalidates node' do
            expect {
              child_3.move_to_child_of(child_3)
            }.to change(child_3, :valid?).from(true).to(false)
          end
        end

        context 'moving to child of current parent' do
          it 'does not move node' do
            expect {
              child_2.move_to_child_of(root)
            }.not_to change(child_2, :reload)
          end
        end

        context 'moving to child of descendant' do
          it { expect(root.move_to_child_of(child_1)).to be_false }

          it 'does node move node' do
            expect {
              root.move_to_child_of(child_1)
            }.not_to change(root, :reload)
          end

          it 'invalidates node' do
            expect {
              root.move_to_child_of(child_1)
            }.to change(root, :valid?).from(true).to(false)
          end
        end

        context 'moving node deeper' do
          before { child_3.move_to_child_of(child_2) }

          expect_tree_to_match {
            root {
              child_1
              child_2 {
                child_3 {
                  child_4
                }
              }
            }
          }
        end

        context 'moving node upper' do
          before { child_4.move_to_child_of(root) }

          expect_tree_to_match {
            root {
              child_1
              child_2
              child_3
              child_4
            }
          }
        end
      end

      context 'when ID given' do
        it 'moves node' do
          expect {
            child_3.move_to_child_of(child_1.id)
          }.to change(child_3, :parent).from(root).to(child_1)
        end

        it 'does not move node if parent was not changed' do
          expect {
            child_2.move_to_child_of(root.id)
          }.not_to change(child_2, :reload)
        end

        context 'moving to non-existent ID' do
          before { child_3.stub(:valid?).and_return(false) }

          it { expect(child_3.move_to_child_of(-1)).to be_false }

          it 'does not move node' do
            expect {
              child_3.move_to_child_of(-1)
            }.not_to change(child_3, :reload)
          end
        end
      end

      context 'when nil given' do
        before { child_2.move_to_child_of(nil) }

        expect_tree_to_match {
          root {
            child_1
            child_3 {
              child_4
            }
          }
          child_2
        }
      end
    end
  end

  include_examples '#move_to_child_of', :default
  include_examples '#move_to_child_of', :default_with_counter_cache
  include_examples '#move_to_child_of', :scoped
end