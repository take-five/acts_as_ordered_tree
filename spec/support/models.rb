class Default < ActiveRecord::Base
  self.table_name = "categories"

  acts_as_ordered_tree
end

class RenamedColumns < ActiveRecord::Base
  acts_as_ordered_tree :parent_column => :mother_id,
                       :position_column => :red,
                       :depth_column => :pitch
end

class DefaultWithCounterCache < ActiveRecord::Base
  self.table_name = "categories"

  acts_as_ordered_tree :counter_cache => :categories_count
end

class DefaultWithCallbacks < ActiveRecord::Base
  self.table_name = "categories"

  acts_as_ordered_tree

  after_move     :after_move
  before_move    :before_move
  after_reorder  :after_reorder
  before_reorder :before_reorder

  def after_move; end
  def before_move; end
  def after_reorder; end
  def before_reorder; end
end

class Scoped < ActiveRecord::Base
  self.table_name = "scoped"

  acts_as_ordered_tree :scope => :scope_type
end