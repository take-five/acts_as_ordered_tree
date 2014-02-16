# coding: utf-8

require 'acts_as_ordered_tree/compatibility/features'

module ActsAsOrderedTree
  # Since we support multiple Rails versions, we need to turn on some features
  # for old Rails versions.
  #
  # @api private
  module Compatibility
    features do
      versions '< 3.1.0' do
        scope :arel do
          feature :as
          feature 'nodes/infix' => :math
          feature :alias_predication
          feature :star
          feature :arbitrary_attribute
        end

        scope 'arel/nodes' do
          feature :and
          feature :named_function
          feature :with
        end

        feature 'active_record/connection_adapters/logger'
        feature 'active_record/associations'
      end

      scope 'active_record/associations' do
        feature :belongs_to_scope => :association_proxy, :versions => '< 3.1.0'
        feature :association, :versions => ['>= 3.1.0', '< 4.0.0']
      end

      feature 'active_record/null_relation', '< 4.0.0'

      feature 'arel/nodes/postgres_array', '>= 3.0.0'
    end
  end
end