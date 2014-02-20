# coding: utf-8

require 'acts_as_ordered_tree/compatibility/features'

module ActsAsOrderedTree
  # Since we support multiple Rails versions, we need to turn on some features
  # for old Rails versions.
  #
  # @api private
  module Compatibility
    features do
      scope 'active_record/associations' do
        feature :association, :versions => ['>= 3.1.0', '< 4.0.0']
      end

      feature 'active_record/null_relation', '< 4.0.0'
      feature 'arel/nodes/postgres_array', '>= 3.1.0'
    end
  end
end