module ActsAsOrderedTree
  module Arrangeable
    # Arrange associated collection into a nested hash of the form
    # {node => children}, where children = {} if the node has no children.
    def arrange
      each_with_object(Hash.new) do |node, result|
        insertion_point = result

        _ancestors(node).each { |a| insertion_point = (insertion_point[a] ||= {}) }

        insertion_point[node] = {}
      end
    end

    private
    # nodes cache (by ID)
    def _cache
      @_cache ||= each_with_object(Hash.new) do |node, cache|
        cache[node.id] = node if node.id
      end
    end

    def _ancestors(node)
      parent = _parent(node)
      parent ? _ancestors(parent) + [parent] : []
    end

    # get parent node of +node+
    def _parent(node)
      _cache[node[node.parent_column]]
    end
  end
end