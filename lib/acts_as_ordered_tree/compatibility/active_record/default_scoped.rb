module ActiveRecord
  module Scoping
    module Default
      module ClassMethods
        # default_scoped is a new method from Rails 4.1.
        # Used in RecursiveRelation
        def default_scoped
          scope = relation.merge(send(:build_default_scope))
          scope.default_scoped = true
          scope
        end
      end
    end
  end
end

ActsAsOrderedTree::Compatibility.version '< 3.2.0' do
  ActiveRecord::Base.extend(ActiveRecord::Scoping::Default::ClassMethods)
end