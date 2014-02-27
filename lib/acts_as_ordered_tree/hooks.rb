# coding: utf-8

require 'active_support/concern'

require 'acts_as_ordered_tree/hooks/update'

module ActsAsOrderedTree
  # Included into AR::Base this module allows to intercept
  # internal AR calls, such as +create_record+ and execute
  # patched code.
  #
  # Hooks intention is to execute well optimized INSERTs and
  # UPDATEs at certain cases.
  #
  # @example
  #   class Category < ActiveRecord::Base
  #     include ActsAsOrderedTree::Hooks
  #   end
  #
  #   category.hook_update do |update|
  #     update.scope = category.parent.children
  #     update.values = {:counter => Category.arel_table[:counter] + 1}
  #
  #     # all callbacks, including :before_save and :after_save will
  #     # be invoked, but patched UPDATE will be called instead of
  #     # original AR `ActiveRecord::Persistence#update_record`
  #     category.save
  #   end
  #
  # @api private
  module Hooks
    extend ActiveSupport::Concern

    included do
      include Update
    end
  end
end