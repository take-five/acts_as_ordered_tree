# coding: utf-8
module ActsAsOrderedTree
  class FakeScope < ActiveRecord::Relation
    # create fake relation, with loaded records
    #
    # == Usage
    #   FakeScope.new(Category.where(:id => 1), [record])
    #   FakeScope.new(Category, [record]) { where(:id => 1) }
    #   FakeScope.new(Category, [record], :where => {:id => 1}, :order => "id desc")
    def initialize(relation, records, conditions = {})
      relation = relation.scoped if relation.is_a?(Class)

      conditions.each do |method, arg|
        relation = relation.send(method, arg)
      end

      super(relation.klass, relation.table)

      # copy instance variables from real relation
      relation.instance_variables.each do |ivar|
        instance_variable_set(ivar, relation.instance_variable_get(ivar))
      end

      @loaded  = true
      @records = records
    end
  end
end