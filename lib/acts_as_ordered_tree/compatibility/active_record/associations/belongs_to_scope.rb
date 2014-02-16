module ActiveRecord
  module Associations
    class BelongsToAssociation < AssociationProxy
      def scoped
        options = @reflection.options.dup
        (options.keys - [:select, :include, :readonly]).each do |key|
          options.delete key
        end
        options[:conditions] = conditions

        primary_key = @reflection.options[:primary_key] || :id

        @reflection.klass.
            where(primary_key => @owner[@reflection.primary_key_name]).
            apply_finder_options(options)
      end
    end
  end
end