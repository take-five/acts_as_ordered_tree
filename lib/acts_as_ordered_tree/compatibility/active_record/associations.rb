module ActiveRecord
  module Associations
    # Returns the association instance for the given name, instantiating it if it doesn't already exist
    def association(name) #:nodoc:
      association = association_instance_get(name)

      if association.nil?
        reflection  = self.class.reflect_on_association(name)

        association_class = case reflection.macro
          when :belongs_to
            if reflection.options[:polymorphic]
              Associations::BelongsToPolymorphicAssociation
            else
              Associations::BelongsToAssociation
            end
          when :has_and_belongs_to_many
            Associations::HasAndBelongsToManyAssociation
          when :has_many
            if reflection.options[:through]
              Associations::HasManyThroughAssociation
            else
              Associations::HasManyAssociation
            end
          when :has_one
            if reflection.options[:through]
              Associations::HasOneThroughAssociation
            else
              Associations::HasOneAssociation
            end
        end

        association = association_class.new(self, reflection)
        association_instance_set(name, association)
      end

      association
    end
  end
end