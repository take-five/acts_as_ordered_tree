# coding: utf-8

require 'tsort'

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array/wrap'

module ActsAsOrderedTree
  module Compatibility
    UnknownFeature = Class.new(StandardError)

    class Feature
      class Version
        def initialize(operator, version = nil)
          operator, version = operator.split unless version
          operator, version = '=', operator unless version
          operator = '==' if operator == '='

          @operator, @version = operator, version.to_s
        end

        def matches?
          ActiveRecord::VERSION::STRING.send(@operator, @version)
        end

        def to_s
          [@operator, @version].join(' ')
        end
      end

      attr_reader :name, :versions, :prerequisites

      def initialize(name, versions, prerequisites)
        @name = name.to_s
        @versions = Array.wrap(versions).map { |v| Version.new(v) }
        @prerequisites = Array.wrap(prerequisites)
      end

      # Requires dependency
      def require
        Kernel.require(path) if @versions.all?(&:matches?)
      end

      private
      def path
        "acts_as_ordered_tree/compatibility/#{name}"
      end
    end

    class DependencyTree
      include TSort

      def initialize
        @features = Hash.new
      end

      def require
        @features.each_value(&:require)
      end

      def <<(feature)
        feature.prerequisites.each do |pre|
          unless @features.key?(pre.to_s)
            @features[pre.to_s] = Feature.new(pre, feature.versions.map(&:to_s), [])
          end
        end

        @features[feature.name] = feature
      end

      def [](name)
        @features[name.to_s]
      end

      def each_dependency(name, &block)
        raise UnknownFeature, "Unknown compatibility feature #{name}" unless @features.key?(name.to_s)

        each_strongly_connected_component_from(name.to_s, &block)
      end

      private
      def tsort_each_node(&block)
        @features.each_key(&block)
      end

      def tsort_each_child(node, &block)
        @features[node].prerequisites.each(&block) if @features[node]
      end
    end

    class DependencyTreeBuilder
      attr_reader :tree

      def initialize
        @tree = DependencyTree.new
        @default_versions = nil
        @prerequisites = []
        @scope = ''
      end

      def versions(*versions, &block)
        @default_versions = versions

        instance_eval(&block)
      ensure
        @default_versions = nil
      end
      alias_method :version, :versions

      def scope(name, &block)
        if name.is_a?(Hash)
          @scope = name.keys.first.to_s
          @prerequisites = Array.wrap(name.values.first)
        else
          @scope = name.to_s
        end

        instance_eval(&block)
      ensure
        @scope = ''
        @prerequisites = []
      end

      def feature(name, options = {})
        @tree << if name.is_a?(Hash)
          version = name.delete(:versions) || @default_versions
          name, prereq = *name.first

          prereq = @prerequisites + Array.wrap(prereq).map { |x| [@scope, x].join('/') }

          Feature.new([@scope, name].join('/'), version, prereq)
        else
          version = options.is_a?(Hash) ? options.delete(:versions) : options
          Feature.new([@scope, name].join('/'), version || @default_versions, @prerequisites)
        end
      end
    end

    module DSL
      def features(&block)
        builder = DependencyTreeBuilder.new
        builder.instance_eval(&block)
        builder.tree.require
      end

      def version(*versions)
        versions = versions.map { |v| Feature::Version.new(*v) }
        yield if versions.all?(&:matches?)
      end
    end
    extend DSL
  end
end