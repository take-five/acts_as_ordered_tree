# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Relation::Arrangeable, :transactional do
  tree :factory => :default do
    root {
      child_1 {
        grandchild_11
        grandchild_12
      }
      child_2 {
        grandchild_21
        grandchild_22
      }
    }
  end

  specify '#descendants scope should be arrangeable' do
    expect(root.descendants.arrange).to eq Hash[
      child_1 => {
        grandchild_11 => {},
        grandchild_12 => {}
      },
      child_2 => {
        grandchild_21 => {},
        grandchild_22 => {}
      }
    ]
  end

  specify '#self_and_descendants should be arrangeable' do
    expect(root.self_and_descendants.arrange).to eq Hash[
      root => {
        child_1 => {
          grandchild_11 => {},
          grandchild_12 => {}
        },
        child_2 => {
          grandchild_21 => {},
          grandchild_22 => {}
        }
      }
    ]
  end

  specify '#ancestors should be arrangeable' do
    expect(grandchild_11.ancestors.arrange).to eq Hash[
      root => {
        child_1 => {}
      }
    ]
  end

  specify '#self_and_ancestors should be arrangeable' do
    expect(grandchild_11.self_and_ancestors.arrange).to eq Hash[
      root => {
        child_1 => {
          grandchild_11 => {}
        }
      }
    ]
  end

  it 'should not discard orphaned nodes by default' do
    relation = root.descendants.where(root.class.arel_table[:id].not_eq(child_1.id))

    expect(relation.arrange).to eq Hash[
      grandchild_11 => {},
      grandchild_12 => {},
      child_2 => {
        grandchild_21 => {},
        grandchild_22 => {}
      }
    ]
  end

  it 'should discard orphans if option :discard passed' do
    relation = root.descendants.where(root.class.arel_table[:id].not_eq(child_1.id))

    expect(relation.arrange(:orphans => :discard)).to eq Hash[
      child_2 => {
        grandchild_21 => {},
        grandchild_22 => {}
      }
    ]
  end
end