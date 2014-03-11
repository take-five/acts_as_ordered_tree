# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, :transactional do
  tree :factory => :scoped do
    root {
      child_1
      child_2
      child_3
    }
  end

  describe '#move_to_child_of' do
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
    end

    context 'when ID given' do
      class DefaultWithExistenceValidation < Scoped
        validates_presence_of :parent, :if => :parent_id?
      end

      it 'moves node' do
        expect {
          child_3.move_to_child_of(child_1.id)
        }.to change(child_3, :parent).from(root).to(child_1)
      end

      it 'does not move node if parent was not changed' do
        expect {
          child_2.move_to_child_of(root)
        }.not_to change(child_2, :reload)
      end

      context 'moving to non-existent ID' do
        let(:moved) { child_3.becomes(DefaultWithExistenceValidation) }

        it { expect(moved.move_to_child_of(-1)).to be_false }

        it 'does not move node' do
          expect {
            moved.move_to_child_of(-1)
          }.not_to change(moved, :reload)
        end

        it 'invalidates node' do
          expect {
            moved.move_to_child_of(-1)
          }.to change(moved, :valid?).from(true).to(false)
        end
      end
    end
  end
end