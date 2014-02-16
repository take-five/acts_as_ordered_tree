module ActiveRecord
  module Associations
    class AssociationProxy
      def scope
        scoped
      end
    end
  end
end