# coding: utf-8

require 'acts_as_ordered_tree/compatibility/features'

module ActsAsOrderedTree
  # Since we support multiple Rails versions, we need to turn on some features
  # for old Rails versions.
  #
  # @api private
  module Compatibility
    features do
      scope :active_record do
        versions '< 4.0.0' do
          feature :association_scope
          feature :null_relation
        end

        feature :default_scoped, '< 4.1.0'
      end

      feature 'arel/nodes/postgres_array', '>= 3.1.0'
    end
  end
end