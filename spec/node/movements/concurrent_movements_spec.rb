# coding: utf-8

require 'spec_helper'

describe ActsAsOrderedTree::Node::Movements, :non_transactional, :unless => ENV['DB'] == 'sqlite3' do
  class ConcurrentTasks < Array
    def task(&block)
      push block
    end

    def spawn(suite)
      map do |task|
        thread { suite.instance_eval(&task) }
      end.each(&:join)
    end

    private
    def thread(&block)
      Thread.start do
        ActiveRecord::Base.connection_pool.with_connection(&block)
      end
    end
  end

  def self.concurrent(&block)
    tasks = ConcurrentTasks.new
    tasks.instance_eval(&block)

    before do
      tasks.spawn(self)
    end
  end

  shared_examples 'Concurrency support' do |factory, attrs = {}|
    context 'create root nodes in empty tree simultaneously' do
      let(:current_tree) { FactoryGirl.factory_by_name(factory).build_class }

      concurrent do
        3.times { task { create factory, attrs } }
      end

      expect_tree_to_match {
        any
        any
        any
      }
    end

    context 'add root nodes to existing tree simultaneously' do
      tree :factory => factory, :attributes => attrs do
        root
      end

      concurrent do
        3.times { task { create factory, attrs } }
      end

      expect_tree_to_match {
        root
        any
        any
        any
      }
    end

    context 'create nodes on the same level simultaneously' do
      tree :factory => factory do
        root
      end

      concurrent do
        3.times do
          task { create factory, :parent => root }
        end
      end

      expect_tree_to_match {
        root {
          any
          any
          any
        }
      }
    end

    context 'move same node simultaneously' do
      tree :factory => factory, :attributes => attrs do
        node_1
        node_2
        node_3
        node_4
      end

      # node itself isn't thread safe
      def moved_node
        current_tree.find(node_2.id)
      end

      concurrent do
        task { moved_node.move_higher }
        task { moved_node.move_lower }
        task { moved_node.move_to_right_of(node_4) }
      end

      expect_tree_to_match {
        any
        any
        any
        any
      }
    end

    context 'move nodes to same parent simultaneously' do
      tree :factory => factory, :attributes => attrs do
        root
        node_1
        node_2
        node_3
      end

      concurrent do
        task { node_1.move_to_child_of(root) }
        task { node_2.move_to_child_of(root) }
        task { node_3.move_to_child_of(root) }
      end

      expect_tree_to_match {
        root {
          any
          any
          any
        }
      }
    end

    context 'move nodes to left of same root node simultaneously' do
      tree :factory => factory, :attributes => attrs do
        root_1
        root_2 {
          node_1
          node_2
          node_3
        }
      end

      concurrent do
        task { node_1.move_to_left_of(root_2) }
        task { node_2.move_to_left_of(root_2) }
        task { node_3.move_to_left_of(root_2) }
      end

      expect_tree_to_match {
        root_1
        any
        any
        any
        root_2
      }
    end

    context 'move nodes to left of same non-root node simultaneously' do
      tree :factory => factory do
        root {
          child_1
          child_2 {
            node_1
            node_2
            node_3
          }
        }
      end

      concurrent do
        task { node_1.move_to_left_of(child_2) }
        task { node_2.move_to_left_of(child_2) }
        task { node_3.move_to_left_of(child_2) }
      end

      expect_tree_to_match {
        root {
          child_1
          any
          any
          any
          child_2
        }
      }
    end

    context 'move node to right of same root node simultaneously' do
      tree :factory => factory, :attributes => attrs do
        root_1 {
          node_1
          node_2
          node_3
        }
        root_2
      end

      concurrent do
        task { node_1.move_to_right_of(root_1) }
        task { node_2.move_to_right_of(root_1) }
        task { node_3.move_to_right_of(root_1) }
      end

      expect_tree_to_match {
        root_1
        any
        any
        any
        root_2
      }
    end

    context 'move nodes to right of same non-root node simultaneously' do
      tree :factory => factory do
        root {
          child_1 {
            node_1
            node_2
            node_3
          }
          child_2
        }
      end

      concurrent do
        task { node_1.move_to_right_of(child_1) }
        task { node_2.move_to_right_of(child_1) }
        task { node_3.move_to_right_of(child_1) }
      end

      expect_tree_to_match {
        root {
          child_1
          any
          any
          any
          child_2
        }
      }
    end

    context 'move nodes to root simultaneously' do
      tree :factory => factory do
        root {
          node_1
          node_2
          node_3
        }
      end

      concurrent do
        task { node_1.move_to_root }
        task { node_2.move_to_root }
        task { node_3.move_to_root }
      end

      expect_tree_to_match {
        root
        any
        any
        any
      }
    end

    context 'move nodes left simultaneously' do
      tree :factory => factory do
        root {
          node_1
          node_2
          node_3
          node_4
        }
      end

      concurrent do
        task { node_2.move_left }
        task { node_3.move_left }
      end

      expect_tree_to_match {
        root {
          any
          any
          any
          node_4
        }
      }
    end

    context 'move nodes right simultaneously' do
      tree :factory => factory do
        root {
          node_1
          node_2
          node_3
          node_4
        }
      end

      concurrent do
        task { node_2.move_right }
        task { node_3.move_right }
      end

      expect_tree_to_match {
        root {
          node_1
          any
          any
          any
        }
      }
    end

    context 'swap nodes between different branches simultaneously' do
      tree :factory => factory do
        root {
          child_1 {
            swap_1
            other_1
          }
          child_2 {
            other_2
            swap_2
          }
        }
      end

      concurrent do
        task { swap_1.move_to_child_with_position(child_2, 2) }
        task { swap_2.move_to_child_with_position(child_1, 1) }
      end

      expect_tree_to_match {
        root {
          child_1 {
            swap_2
            other_1
          }
          child_2 {
            other_2
            swap_1
          }
        }
      }
    end
  end

  include_examples 'Concurrency support', :default
  include_examples 'Concurrency support', :default_with_counter_cache
  include_examples 'Concurrency support', :scoped, :scope_type => 's'
end