# coding: utf-8

require 'tsort'

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array/wrap'

module ActsAsOrderedTree
  # Since we support multiple Rails versions, we need to turn on some features
  # for old Rails versions.
  #
  # @api private
  module Compatibility
    UnknownFeature = Class.new(StandardError)
    module DSL
      include TSort

      # Declare compatibility feature
      # @example
      #   feature 'arel/math', '<= 3.1.0'
      #   feature 'arel/nodes/infix' => 'arel/math', :versions => '<= 3.1.0'
      def feature(name, versions = nil)
        if name.is_a?(Hash)
          versions = name[:versions]
          name, dep = name.keys.first.to_s, Array.wrap(name.values.first).map(&:to_s)
          dependencies[name] = [versions.split, dep]
        else
          dependencies[name.to_s] = [versions.split, []]
        end
      end

      # Require all features
      def require_features!
        @dependencies.each_key { |f| self.require f }
      end

      # Include feature if needed
      def require(feature)
        each_dependency(feature) { |f| require_feature f }
      end

      private
      def tsort_each_node(&block)
        @dependencies.each_key(&block)
      end

      def tsort_each_child(node, &block)
        _, dep = @dependencies[node]
        (dep || []).each(&block)
      end

      def dependencies
        @dependencies ||= {}
      end

      def each_dependency(feature)
        raise UnknownFeature, "Unknown compatibility feature #{feature}" unless dependencies.key?(feature.to_s)

        each_strongly_connected_component_from(feature) { |*, f| yield f }
      end

      def require_feature(feature)
        operator, version = dependencies[feature].first

        if ActiveRecord::VERSION::STRING.send(operator, version)
          Kernel.require "acts_as_ordered_tree/compatibility/#{feature}"
        end
      end
    end

    extend DSL

    feature 'arel/math', '<= 3.1.0'
    feature 'arel/nodes/infix' => 'arel/math', :versions => '<= 3.1.0'
    feature 'arel/nodes/and', '<= 3.1.0'
    feature 'arel/nodes/named_function', '<= 3.1.0'

    feature 'active_record/connection_adapters/logger', '<= 3.1.0'

    require_features!
  end
end