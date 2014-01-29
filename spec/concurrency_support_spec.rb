require 'spec_helper'

# Sqlite is not concurrent database
if ENV['DB'] != 'sqlite3'
  describe ActsAsOrderedTree, :non_transactional do
    module Concurrency
      # run block in its own thread, create +size+ threads
      def pool(size)
        size.times.map { |x|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection { yield x }
          end
        }.each(&:join)
      end
    end
    include Concurrency

    let!(:root) { create :default }

    # prints tree
    def ptree(node = nil)
      node ||= Default.root

      puts ('  ' * node.level) + node.name
      node.children.each { |c| ptree(c) }
    end

    it 'should not create nodes with same position' do
      pool(3) do
        create :default, :parent => root
      end

      root.children.map(&:position).should eq [1, 2, 3]
    end

    it 'should not move nodes to same position when moving to child of certain node' do
      nodes = create_list :default, 3

      pool(3) do |x|
        nodes[x].move_to_child_of(root)
      end

      root.children.map(&:position).should eq [1, 2, 3]
    end

    it 'should not move nodes to same position when moving to left of root node' do
      nodes = create_list :default, 3, :parent => root

      pool(3) do |x|
        nodes[x].move_to_left_of(root)
      end

      Default.roots.map(&:position).should eq [1, 2, 3, 4]
    end

    it 'should not move nodes to same position when moving to left of child node' do
      child = create :default, :parent => root
      nodes = create_list :default, 3, :parent => child

      pool(3) do |x|
        nodes[x].move_to_left_of(child)
      end

      root.children.map(&:position).should eq [1, 2, 3, 4]
      root.children.last.should eq child
    end

    it 'should not move nodes to same position when moving to right of child node' do
      child = create :default, :parent => root
      nodes = create_list :default, 3, :parent => child

      pool(3) do |x|
        nodes[x].move_to_right_of(child)
      end

      root.children.map(&:position).should eq [1, 2, 3, 4]
      root.children.first.should eq child
    end

    it 'should not move nodes to same position when moving to root' do
      nodes = create_list :default, 3, :parent => root

      pool(3) do |x|
        nodes[x].move_to_root
      end

      Default.roots.map(&:position).should eq [1, 2, 3, 4]
    end

    # checking deadlock also
    it 'should not move nodes to same position when moving to specified index' do
      # root
      # * child1
      #   * nodes1_1
      #   * nodes1_2
      # * child2
      #   * nodes2_1
      #   * nodes2_2
      child1, child2 = create_list :default, 2, :parent => root

      nodes1, nodes2 = create_list(:default, 2, :parent => child1),
                       create_list(:default, 2, :parent => child2)

      nodes1_1, nodes1_2 = nodes1
      nodes2_1, nodes2_2 = nodes2

      # nodes2_2 -> child1[0]
      thread1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          nodes2_2.move_to_child_with_index(child1, 0)
        end
      end
      # nodes1_1 -> child2[2]
      thread2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          nodes1_1.move_to_child_with_index(child2, 2)
        end
      end
      [thread1, thread2].map(&:join)

      child1.children.reload.should == [nodes2_2, nodes1_2]
      child2.children.reload.should == [nodes2_1, nodes1_1]
    end

    it 'should not move nodes to same position when moving higher' do
      child1, child2, child3 = create_list :default, 3, :parent => root

      thread1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          child2.move_higher
        end
      end
      thread2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          child3.move_higher
        end
      end

      [thread1, thread2].map(&:join)

      root.children.map(&:position).should eq [1, 2, 3]
    end

    it 'should not move nodes to same position when moving lower' do
      child1, child2, child3 = create_list :default, 3, :parent => root

      thread1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          child1.move_lower
        end
      end
      thread2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          child2.move_lower
        end
      end

      [thread1, thread2].map(&:join)

      root.children.map(&:position).should eq [1, 2, 3]
    end
  end
end